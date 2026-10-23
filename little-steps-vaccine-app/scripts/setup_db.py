#!/usr/bin/env python3
"""Initialize a NEW database; never drop or overwrite an existing schema."""
import argparse
import os
from pathlib import Path
import sys
import psycopg
from psycopg import sql
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / '.env')
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--create', action='store_true', help='Create DB_NAME using the configured local login')
parser.add_argument('--migrate-only', action='store_true', help='Apply all additive project migrations to an already initialized project DB')
args = parser.parse_args()
required = ['DB_NAME', 'DB_USER', 'DB_PASSWORD']
if any(not os.getenv(k) or os.getenv(k)=='replace_me' for k in required):
    sys.exit('Fill in .env (DB_NAME, DB_USER, DB_PASSWORD) first. Never share this file.')
params = dict(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','5432')),user=os.environ['DB_USER'],password=os.environ['DB_PASSWORD'],connect_timeout=5)
name = os.environ['DB_NAME']
if name != '9120assignment_demo':
    sys.exit('Refusing database setup: DB_NAME must be 9120assignment_demo. Other databases must not be modified.')
try:
    if args.create:
        with psycopg.connect(dbname='postgres', autocommit=True, **params) as admin:
            if not admin.execute('SELECT 1 FROM pg_database WHERE datname=%s',(name,)).fetchone():
                admin.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(name)))
                print(f'Created database {name}.')
            else:
                print(f'Database {name} exists. Checking it before making changes.')
    with psycopg.connect(dbname=name, **params) as conn:
        if not args.migrate_only:
            tables = conn.execute("SELECT tablename FROM pg_tables WHERE schemaname='public'").fetchall()
            if tables:
                sys.exit('Refusing to initialize: public already has tables. Use a new empty database. For additive migrations only, run --migrate-only.')
            conn.execute((ROOT/'schema.sql').read_text(), prepare=False)
            conn.execute((ROOT/'seed.sql').read_text(), prepare=False)
        for migration in sorted((ROOT/'migrations').glob('*.sql')):
            conn.execute(migration.read_text(), prepare=False)
        counts = conn.execute('SELECT (SELECT count(*) FROM vaccine), (SELECT count(*) FROM recommended_schedule), (SELECT count(*) FROM parent)').fetchone()
    print(f'Initialized. Vaccines: {counts[0]}; recommended doses: {counts[1]}; parents: {counts[2]}.')
except psycopg.Error as exc:
    sys.exit(f'Database setup failed ({type(exc).__name__}). Check server, credentials, and create-database permission. No existing tables were dropped.')
