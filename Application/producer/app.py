import json, time, requests
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

while True:
    try:
        res = requests.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson')
        #res = requests.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson')
        data = res.json()['features']
        for quake in data:
            producer.send('earthquakes', quake)
        print(f"Published {len(data)} earthquakes.")
    except Exception as e:
        print("Error:", e)

    time.sleep(60)
