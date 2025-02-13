import psycopg2
import os

# Load the database connection URI from environment variable
DATABASE_URL = os.getenv('DATABASE_URL', 'postgres://api:password@postgresql.database.svc.cluster.local:5432/api')

# Establish connection
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Create tables
cur.execute("""
    CREATE TABLE IF NOT EXISTS mytable (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        created_at TIMESTAMP
    );
""")

cur.execute("""
    CREATE TABLE IF NOT EXISTS othertable (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        created_at TIMESTAMP
    );
""")

# Commit changes and close connection
conn.commit()
cur.close()
conn.close()

print("Tables created successfully.")