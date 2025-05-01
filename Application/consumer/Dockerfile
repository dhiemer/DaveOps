FROM python:3.11-slim

WORKDIR /app

COPY app.py .

RUN pip install kafka-python psycopg2-binary requests

CMD ["python", "app.py"]
