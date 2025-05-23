kubectl get pods
kubectl exec -it postgres-77d46f48f5-n8nbf -- psql -U postgres -d postgres
MiWx9oYY8U
\dt
\d quakes
ALTER TABLE quakes ADD COLUMN time timestamp;

SELECT * FROM quakes ORDER BY time;
SELECT * FROM quakes ORDER BY time DESC LIMIT 10;
TRUNCATE TABLE quakes;
\q




kubectl exec -it postgres-5c78cf7bf-ph4lz -- bash

psql -U postgres -d quakes

CREATE TABLE quakes (
    quake_id TEXT PRIMARY KEY,
    place TEXT,
    magnitude REAL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    time TIMESTAMP
);

# Step 4: Optional verification
\d quakes;

# Step 5: Exit
\q
exit
