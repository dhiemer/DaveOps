from flask import Flask, jsonify, Response
import psycopg2
import json
import os

app = Flask(__name__)

DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT')
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
    with open('/app/index.html') as f:
        return Response(f.read(), mimetype='text/html')

@app.route('/data.json')
def data_json():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT latitude, longitude, magnitude, place, time FROM quakes ORDER BY time DESC LIMIT 100')
    rows = cur.fetchall()
    conn.close()

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
                "time": quake_time.isoformat()  # 💥 Use actual earthquake time
            }
        })

    return jsonify(features)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
