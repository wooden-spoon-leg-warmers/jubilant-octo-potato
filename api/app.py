from flask import Flask, jsonify
import psycopg2
import os
import yaml

app = Flask(__name__)

# Load the database connection URI from environment variable
DATABASE_URL = os.getenv('DATABASE_URL', 'postgres://api:password@postgresql.database.svc.cluster.local:5432/api')

# Load configuration from YAML file
with open('config/mapping.yaml', 'r') as file:
    config = yaml.safe_load(file)

# Create a lookup dictionary for API endpoints
endpoint_mappings = {mapping['api_endpoint']: mapping for mapping in config['mappings']}

@app.route("/<string:path>")
@app.route("/<path:path>")
def index(path):
    api_endpoint = f"/{path}"
    if api_endpoint not in endpoint_mappings:
        return jsonify({'error': 'API endpoint not found'}), 404

    mapping = endpoint_mappings[api_endpoint]
    query = mapping['query']

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        cur.execute(query)
        data = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify(transform_data(data, mapping['columns']))
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route("/health")
def health():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return jsonify({'status': 'healthy'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

def transform_data(data, columns):
    transformed_data = []
    for row in data:
        transformed_row = {columns[col_name]: value for col_name, value in zip(columns.keys(), row)}
        transformed_data.append(transformed_row)
    return transformed_data

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)