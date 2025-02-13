import psycopg2
import os
from datetime import datetime

# Load the database connection URI from environment variable
DATABASE_URL = os.getenv('DATABASE_URL', 'postgres://api:password@postgresql.database.svc.cluster.local:5432/api')

# Establish connection
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Insert data into mytable with ON CONFLICT clause
cur.execute("""
    INSERT INTO mytable (id, name, created_at) VALUES
    ('1', 'Sample Name 1', %s),
    ('2', 'Sample Name 2', %s)
    ON CONFLICT (id) DO NOTHING;
""", (datetime.now(), datetime.now()))

# Insert data into othertable with ON CONFLICT clause
cur.execute("""
    INSERT INTO othertable (id, name, created_at) VALUES
    ('1', 'Other Sample Name 1', %s),
    ('2', 'Other Sample Name 2', %s)
    ON CONFLICT (id) DO NOTHING;
""", (datetime.now(), datetime.now()))

# Commit changes and close connection
conn.commit()
cur.close()
conn.close()

print("Data inserted successfully.")