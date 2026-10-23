"""REAL PostgreSQL tests in a fresh, private schema. Skipped without explicit opt-in.
Run RUN_DB_TESTS=1 python -m pytest tests/test_postgres.py -v after configuring .env.
The schema and its fixture data are dropped at teardown; existing public tables are untouched.
"""
from datetime import date, timedelta
from pathlib import Path
import os
import uuid
import pytest
import psycopg
from psycopg import sql
from fastapi.testclient import TestClient
from app.main import app
from app.db import connection_kwargs

pytestmark=pytest.mark.skipif(os.getenv('RUN_DB_TESTS')!='1',reason='Requires configured PostgreSQL and RUN_DB_TESTS=1')
ROOT=Path(__file__).resolve().parents[1]

@pytest.fixture(scope='module')
def db_client():
    schema='test_little_steps_'+uuid.uuid4().hex
    params=connection_kwargs()
    with psycopg.connect(**params,autocommit=True) as conn:
        conn.execute(sql.SQL('CREATE SCHEMA {}').format(sql.Identifier(schema)))
    original_options=params.get('options','')
    params['options']=original_options+f' -c search_path={schema},public'
    try:
        with psycopg.connect(**params) as conn:
            for p in [ROOT/'schema.sql',ROOT/'seed.sql',ROOT/'migrations/001_mobile.sql']:
                conn.execute(p.read_text(),prepare=False)
        from unittest.mock import patch
        with patch('app.db.connection_kwargs',return_value=params):
            yield TestClient(app),params
    finally:
        with psycopg.connect(**connection_kwargs(),autocommit=True) as conn:
            conn.execute(sql.SQL('DROP SCHEMA {} CASCADE').format(sql.Identifier(schema)))

def test_complete_database_flow(db_client):
    client,params=db_client
    assert client.get('/health').status_code==200
    vaccines=client.get('/vaccines').json()
    doses=client.get('/schedules/recommended').json()
    assert len(vaccines)==22 and len(doses)>22
    assert {0, 2, 4, 6, 12, 18, 48, 144, 168}.issubset({v['recommended_months'] for v in doses})
    parent=client.post('/parents',json={'name':'  Alex Test  '})
    assert parent.status_code==201
    parent=parent.json()
    dob=(date.today()-timedelta(days=150)).isoformat()
    created=client.post('/children',json={'name':'Emma Test','date_of_birth':dob,'parent_id':parent['parent_id']})
    assert created.status_code==201
    child=created.json()
    assert child['schedules_created']==len(doses)
    schedules=client.get('/schedules',params={'child_id':child['child_id']}).json()
    reminders=client.get('/reminders',params={'child_id':child['child_id']}).json()
    assert len(schedules)==len(reminders)==len(doses)
    assert client.get('/children/'+child['child_id']).status_code==200
    dose=next(s for s in schedules if s['vaccine_name']=='Engerix B')
    reminder=next(r for r in reminders if r['schedule_id']==dose['schedule_id'])
    reminder_path='/reminders/'+reminder['reminder_id']
    reminder_time=date.today().isoformat()+'T09:30:00'
    assert client.patch(reminder_path,json={'reminder_date':reminder_time}).status_code==200
    moved=(date.today()+timedelta(days=3)).isoformat()
    assert client.patch('/schedules/'+dose['schedule_id'],json={'scheduled_date':moved,'provider':'Test Clinic'}).status_code==200
    refreshed=client.get('/reminders',params={'child_id':child['child_id']}).json()
    assert next(r for r in refreshed if r['reminder_id']==reminder['reminder_id'])['reminder_date']==moved+'T09:30:00'
    record={'child_id':child['child_id'],'vaccine_id':dose['vaccine_id'],'dose_number':dose['dose_number'],'vaccination_date':date.today().isoformat()+'T12:00:00','provider':'Test Clinic'}
    saved=client.post('/records',json=record)
    assert saved.status_code==201 and saved.json()['schedule']['status']=='completed'
    assert client.post('/records',json=record).status_code==409
    assert client.patch(reminder_path,json={'reminder_status':'pending'}).status_code==409
    assert client.patch('/schedules/'+dose['schedule_id'],json={'scheduled_date':moved,'status':'pending'}).status_code==409
    assert len(client.get('/records',params={'child_id':child['child_id']}).json())==1
    assert len(client.get('/reminders',params={'child_id':child['child_id'],'status':'completed'}).json())==1
    assert client.get('/dashboard').json()['vaccinations_recorded']==1
    with psycopg.connect(**params) as conn:
        row=conn.execute('SELECT status FROM vaccine_schedule WHERE schedule_id=%s',(dose['schedule_id'],)).fetchone()
        assert row['status']=='completed'

def test_database_rejections(db_client):
    client,_=db_client
    assert client.post('/children',json={'name':'Test','date_of_birth':'2026-01-01','parent_id':'P99999'}).status_code==404
    assert client.patch('/schedules/S99999',json={'scheduled_date':date.today().isoformat()}).status_code==404
    assert client.patch('/reminders/R99999',json={'reminder_status':'pending'}).status_code==404
