-- Run individual blocks in PostgreSQL after schema.sql / migrations.
-- Replace the IDs with existing demo IDs. The first example saves nothing.
BEGIN;
SELECT delete_child('C00001');
-- Inspect the deletion within this transaction.
SELECT * FROM child WHERE child_id='C00001';
ROLLBACK;
-- The child and all cascaded rows are restored.

-- COMMIT examples below are commented to avoid deleting data if this whole
-- demonstration file is executed accidentally. Select and uncomment ONE block.
-- BEGIN;
-- SELECT delete_child('C00001');
-- COMMIT;

-- BEGIN;
-- SELECT delete_vaccination_record('D00001');
-- COMMIT;

-- BEGIN;
-- SELECT delete_parent('P00001');
-- COMMIT;

-- If a statement fails before COMMIT, execute ROLLBACK in the same session.
-- PostgreSQL sequence values are not restored by ROLLBACK; gaps are normal.
