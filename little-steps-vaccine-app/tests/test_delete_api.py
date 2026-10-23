"""HTTP delete and transaction tests with a mocked database connection."""
from unittest.mock import MagicMock, patch
import pytest
import psycopg
from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)

@pytest.mark.parametrize('path,function', [('/children/C00001','delete_child'),('/records/D00001','delete_vaccination_record'),('/parents/P00001','delete_parent')])
@pytest.mark.parametrize('outcome,status', [('success',200),('missing',404),('failure',503),('commit_failure',503)])
def test_delete_transaction(path, function, outcome, status):
    conn = MagicMock()
    cur = conn.cursor.return_value.__enter__.return_value
    cur.fetchone.return_value = {'deleted': outcome != 'missing'}
    if outcome == 'failure':
        cur.execute.side_effect = psycopg.OperationalError('private database details')
    if outcome == 'commit_failure':
        conn.commit.side_effect = psycopg.OperationalError('private database details')
    with patch('app.db.connection_kwargs', return_value={}), patch('app.db.psycopg.connect', return_value=conn):
        response = client.delete(path)
    assert response.status_code == status
    assert 'private database details' not in response.text
    cur.execute.assert_called_once_with(f'SELECT {function}(%s) AS deleted', (path.split('/')[-1],))
    if outcome == 'success':
        conn.commit.assert_called_once()
        conn.rollback.assert_not_called()
    else:
        conn.rollback.assert_called_once()
    conn.close.assert_called_once()
