import json
import psycopg2
from kafka import KafkaConsumer
import os
import time

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")

# Connect to PostgreSQL
def connect_db():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                port=DB_PORT,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            conn.autocommit = True
            return conn
        except Exception as e:
            print("Waiting for database...")
            time.sleep(2)

conn = connect_db()
cur = conn.cursor()

# Create table if it doesn't exist
cur.execute('''
CREATE TABLE IF NOT EXISTS quakes (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT now(),
    place TEXT,
    magnitude REAL,
    latitude REAL,
    longitude REAL
);
''')

print("Connecting to Kafka...")
consumer = KafkaConsumer(
    'earthquakes',
    bootstrap_servers=['kafka:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

print("Connected. Waiting for messages...")

for message in consumer:
    quake = message.value
    print("Raw message received:", quake)

    try:
        # Extract values safely
        place = quake.get('properties', {}).get('place')
        magnitude = quake.get('properties', {}).get('mag')
        coordinates = quake.get('geometry', {}).get('coordinates', [None, None])

        lon = coordinates[0]
        lat = coordinates[1]

        if place and magnitude is not None and lat is not None and lon is not None:
            cur.execute(
                "INSERT INTO quakes (place, magnitude, latitude, longitude) VALUES (%s, %s, %s, %s)",
                (place, magnitude, lat, lon)
            )
            print(f"Inserted quake: {place} | Mag {magnitude} | Lat {lat} | Lon {lon}")
        else:
            print("Skipping quake, missing data.")
    except Exception as e:
        print("Error inserting quake:", e)
