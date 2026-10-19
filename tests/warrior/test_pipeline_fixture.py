"""Executable SQLite fixture: replay, ties, deletes, backfill and rollback."""
import sqlite3,unittest

def setup():
 db=sqlite3.connect(':memory:')
 db.executescript('''
 CREATE TABLE target(order_id TEXT PRIMARY KEY, amount INTEGER NOT NULL, version INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
 CREATE TABLE checkpoint(source TEXT PRIMARY KEY, position INTEGER NOT NULL);
 CREATE TABLE changes(seq INTEGER PRIMARY KEY, order_id TEXT NOT NULL, amount INTEGER NOT NULL, version INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
 ''')
 return db

def apply(db,through,fail=False):
 """A deterministic reference implementation; the agent under evaluation must build its own."""
 db.execute('BEGIN')
 try:
  last=db.execute("SELECT COALESCE((SELECT position FROM checkpoint WHERE source='orders'),0)").fetchone()[0]
  events=db.execute('SELECT seq,order_id,amount,version,deleted FROM changes WHERE seq>? AND seq<=? ORDER BY seq',(last,through)).fetchall()
  for seq,key,amount,version,deleted in events:
   db.execute('''INSERT INTO target(order_id,amount,version,deleted) VALUES(?,?,?,?)
    ON CONFLICT(order_id) DO UPDATE SET amount=excluded.amount,version=excluded.version,deleted=excluded.deleted
    WHERE excluded.version>target.version''',(key,amount,version,deleted))
  if fail:raise RuntimeError('simulated write failure')
  db.execute("INSERT INTO checkpoint(source,position) VALUES('orders',?) ON CONFLICT(source) DO UPDATE SET position=excluded.position",(through,))
  db.commit()
 except Exception:
  db.rollback()
  raise

class PipelineFixture(unittest.TestCase):
 def setUp(self):
  self.db=setup()
  self.db.executemany('INSERT INTO changes VALUES(?,?,?,?,?)',[
   (1,'A',100,1,0),(2,'A',120,2,0),(3,'B',200,1,0),
   (4,'A',120,2,0),(5,'B',200,2,1),(6,'A',90,1,0)])
  self.db.commit()
 def state(self):
  return self.db.execute('SELECT * FROM target ORDER BY order_id').fetchall()
 def test_initial_and_updates(self):
  apply(self.db,3)
  self.assertEqual(self.state(),[('A',120,2,0),('B',200,1,0)])
 def test_replay_is_idempotent(self):
  apply(self.db,4)
  first=self.state()
  apply(self.db,4)
  self.assertEqual(self.state(),first)
 def test_delete_tombstone_and_late_old_event(self):
  apply(self.db,6)
  self.assertEqual(self.state(),[('A',120,2,0),('B',200,2,1)])
 def test_checkpoint_atomic_on_failure(self):
  with self.assertRaises(RuntimeError):apply(self.db,3,fail=True)
  self.assertEqual(self.state(),[])
  self.assertEqual(self.db.execute('SELECT count(*) FROM checkpoint').fetchone()[0],0)
  apply(self.db,6)
  self.assertEqual(len(self.state()),2)
if __name__=='__main__':unittest.main()
