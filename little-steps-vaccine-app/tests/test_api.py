"""Unit/HTTP tests; DB-independent. They do NOT prove PostgreSQL integration."""
from datetime import date, timedelta
from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

@pytest.mark.parametrize('path',['/','/static/app.js','/static/style.css','/static/manifest.webmanifest','/static/icon-192.png','/static/apple-touch-icon.png','/docs','/openapi.json'])
def test_ui_and_api_assets(path):
    assert client.get(path).status_code == 200

def test_api_routes_preserved():
    paths=client.get('/openapi.json').json()['paths']
    assert all(p in paths for p in ['/parents','/children','/vaccines','/records','/reminders','/schedules','/dashboard'])
    reminder=client.get('/openapi.json').json()['components']['schemas']['ReminderUpdate']['properties']
    assert 'reminder_date' in reminder and 'reminder_status' in reminder

@pytest.mark.parametrize('name',['','   ','x'*101])
def test_parent_name_invalid(name):
    assert client.post('/parents',json={'name':name}).status_code == 422

def test_names_trimmed():
    from app.schemas import ParentCreate
    assert ParentCreate(name='  Alex  ').name == 'Alex'

@pytest.mark.parametrize('body',[{'name':'Emma','parent_id':'bad','date_of_birth':'2026-01-01'},{'name':'Emma','parent_id':'P00001','date_of_birth':(date.today()+timedelta(days=1)).isoformat()}])
def test_invalid_child(body):
    assert client.post('/children',json=body).status_code == 422

@pytest.mark.parametrize('changes',[{}, {'reminder_date':None},{'reminder_status':'overdue'},{'reminder_date':'not-a-date'},{'reminder_date':'2026-10-20T12:00:00Z'}])
def test_invalid_reminder(changes):
    assert client.patch('/reminders/R00001',json=changes).status_code == 422

@pytest.mark.parametrize('changes',[{'reminder_status':'pending'},{'reminder_date':'2026-10-20T09:00:00'}])
def test_valid_reminder_model(changes):
    from app.schemas import ReminderUpdate
    assert ReminderUpdate(**changes)

def test_future_record():
    assert client.post('/records',json={'child_id':'C00001','vaccine_id':'V00001','dose_number':1,'vaccination_date':(date.today()+timedelta(days=1)).isoformat()+'T12:00:00'}).status_code == 422

def test_database_error_is_safe():
    import psycopg
    with patch('app.main.fetch_one',side_effect=psycopg.OperationalError('password=SECRET')):
        response=client.get('/health')
    assert response.status_code == 503 and 'SECRET' not in response.text

def test_missing_config_is_safe():
    with patch('app.main.fetch_all',side_effect=RuntimeError('SECRET')):
        response=client.get('/parents')
    assert response.status_code == 503 and 'SECRET' not in response.text

def test_database_target_is_restricted(monkeypatch):
    from app.db import connection_kwargs
    monkeypatch.setenv('DB_NAME','unrelated_database')
    monkeypatch.setenv('DB_USER','test_user')
    monkeypatch.setenv('DB_PASSWORD','test_password')
    with pytest.raises(RuntimeError,match='DB_NAME must be 9120assignment_demo'):
        connection_kwargs()

@pytest.mark.parametrize('path',['/schedules?status=invalid','/reminders?status=overdue'])
def test_status_query_invalid(path):
    assert client.get(path).status_code == 422
