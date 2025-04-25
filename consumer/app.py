import json
import os
import psycopg2
from kafka import KafkaConsumer

DB_HOST = os.environ.get('DB_HOST', 'earthquake-postgres-postgresql.default.svc.cluster.local')
DB_PORT = int(os.environ.get('DB_PORT', 5432))
DB_NAME = os.environ.get('DB_NAME', 'postgres')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'changeme')

consumer = KafkaConsumer(
    'earthquakes',
    bootstrap_servers=['kafka:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

print('Connecting to Kafka...')
print('Connected. Waiting for messages...')

while True:
    for message in consumer:
        print(f"Raw message received: {message.value}")  # NEW DEBUG LINE

        quake = message.value
        location = quake.get('properties', {}).get('place')
        magnitude = quake.get('properties', {}).get('mag')

        print(f"Received: {location}")

        try:
            conn = get_db_connection()
            cur = conn.cursor()

            cur.execute(
                "INSERT INTO quakes (timestamp, location, magnitude) VALUES (NOW(), %s, %s)",
                (location, magnitude)
            )

            conn.commit()
            cur.close()
            conn.close()

            print("Inserted into database.")
        except Exception as e:
            print(f"Error inserting quake: {e}")