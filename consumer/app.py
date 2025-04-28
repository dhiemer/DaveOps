import os
import json
import time
import psycopg2
from kafka import KafkaConsumer

DB_HOST = os.getenv('DB_HOST')
DB_PORT = int(os.getenv('DB_PORT', 5432))
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

import time
import psycopg2

def insert_quake(place, magnitude, latitude, longitude, quake_time, quake_id):
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO quakes (place, magnitude, latitude, longitude, time, quake_id)
            VALUES (%s, %s, %s, %s, to_timestamp(%s / 1000.0), %s)
            ON CONFLICT (quake_id) DO NOTHING
            """,
            (place, magnitude, latitude, longitude, quake_time, quake_id)
        )
        conn.commit()
        cur.close()
        conn.close()
        print(f"quake_time: {quake_time}")
        print(f"Inserted quake: {place} - M{magnitude}")
    except Exception as e:
        print(f"Error inserting quake: {e}")


def main():
    print("Connecting to Kafka...")
    consumer = KafkaConsumer(
        'earthquakes',
        bootstrap_servers=['kafka:9092'],
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='earthquake-consumer-group'
    )
    print("Connected. Waiting for messages...")

    for message in consumer:
        quake = message.value
        print(f"Raw message received: {quake}")

        try:
            place = quake['properties']['place']
            magnitude = quake['properties']['mag']
            quake_time = quake['properties']['time']  # **Important**: this is in milliseconds
            longitude = quake['geometry']['coordinates'][0]
            latitude = quake['geometry']['coordinates'][1]
            quake_id = quake['id']

            insert_quake(place, magnitude, latitude, longitude, quake_time, quake_id)

        except Exception as e:
            print(f"Error processing message: {e}")

if __name__ == "__main__":
    main()
