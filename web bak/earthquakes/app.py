from flask import Flask, jsonify, Response, abort
import psycopg2
import os
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

@app.route('/')
def index():
    try:
        with open('/app/index.html', 'r') as f:
            html = f.read()
            return Response(html, mimetype='text/html')
    except Exception as e:
        app.logger.error(f"Error loading index.html: {e}")
        return Response("Internal Server Error", status=500)

@app.route('/data.json')
def data_json():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT latitude, longitude, magnitude, place, time FROM quakes ORDER BY time DESC LIMIT 100')
        rows = cur.fetchall()
        conn.close()
    except Exception as e:
        app.logger.error(f"Database query failed: {e}")
        return jsonify({"error": "Failed to fetch data"}), 500

    features = []
    for lat, lon, mag, place, quake_time in rows:
        features.append({
            "geometry": {
                "type": "Point",
                "coordinates": [lon, lat]
            },
            "properties": {
                "mag": mag,
                "place": place,
                "time": quake_time.isoformat()
            }
        })

    return jsonify(features)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
