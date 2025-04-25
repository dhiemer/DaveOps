from flask import Flask, jsonify, send_from_directory
import psycopg2
import os

app = Flask(__name__, static_folder='/usr/share/nginx/html', static_url_path='')

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'earthquake-postgres-postgresql.default.svc.cluster.local'),
        database=os.environ.get('DB_NAME', 'postgres'),
        user=os.environ.get('DB_USER', 'postgres'),  
        password=os.environ.get('DB_PASSWORD', 'changeme'),
        port=int(os.environ.get('DB_PORT', 5432))
    )

@app.route('/')
def home():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/data.json', strict_slashes=False)  # <-- ✅ FIXED here
def data_json():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT timestamp, location, magnitude FROM quakes ORDER BY timestamp DESC LIMIT 10')
    rows = cur.fetchall()
    cur.close()
    conn.close()

    features = [{
        "properties": {
            "place": row[1],
            "mag": row[2]
        }
    } for row in rows]

    return jsonify(features)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
