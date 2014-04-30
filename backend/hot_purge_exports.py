#!/usr/bin/python
import psycopg2
import os
import os.path
import shutil

PURGE_AFTER_DAYS = 30

DBNAME = 'hot_export_production'
DBUSER = 'hot_export'
DBPASS = 'hot_export'
DBHOST = 'localhost'

RUN_DIRECTORY = '/home/hot/var/runs'

conn = psycopg2.connect(
    'dbname={} user={} password={} host={}'
    .format(DBNAME, DBUSER, DBPASS, DBHOST)
)

cur = conn.cursor()

sql_deleted_jobs = """SELECT j.id
FROM jobs j
WHERE j.visible = 'f' and j.updated_at < (now() - INTERVAL '{} DAYS')
""".format(PURGE_AFTER_DAYS)

sql_delete_tags = """WITH old_jobs AS ({})
DELETE FROM tags t
WHERE t.job_id IN (SELECT id FROM old_jobs)
""".format(sql_deleted_jobs)

print 'Removing tags...',
cur.execute(sql_delete_tags)
print cur.rowcount

sql_delete_downloads = """WITH old_jobs AS ({})
DELETE FROM downloads d
WHERE  d.run_id IN (
        select r.id from runs r INNER JOIN old_jobs j ON r.job_id = j.id
)
""".format(sql_deleted_jobs)

print 'Removing downloads...',
cur.execute(sql_delete_downloads)
print cur.rowcount

sql_collect_runs = """WITH old_jobs AS ({})
SELECT to_char(r.id, '000009')
FROM runs r INNER JOIN old_jobs j ON r.job_id = j.id
""".format(sql_deleted_jobs)

cur.execute(sql_collect_runs)

for run in cur.fetchall():
    run_directory = os.path.join(RUN_DIRECTORY, run[0].strip())
    if os.path.isdir(run_directory):
        print 'Removing ... {}'.format(run_directory)
        shutil.rmtree(run_directory)
    else:
        print '{} is not a directory...'.format(run_directory)

sql_delete_runs = """WITH old_jobs AS ({})
DELETE FROM runs r
WHERE r.job_id IN (select id FROM old_jobs)
""".format(sql_deleted_jobs)

print 'Removing runs...',
cur.execute(sql_delete_runs)
print cur.rowcount

sql_delete_jobs = """WITH old_jobs AS ({})
DELETE FROM jobs j
WHERE j.id IN (select id FROM old_jobs)
""".format(sql_deleted_jobs)

print 'Removing jobs...',
cur.execute(sql_delete_jobs)
print cur.rowcount

conn.commit()
