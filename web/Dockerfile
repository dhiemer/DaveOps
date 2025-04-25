FROM python:3.11-slim

WORKDIR /app

COPY app.py .
COPY static/ /usr/share/nginx/html/

RUN pip install flask psycopg2-binary

ENV FLASK_APP=app.py

CMD ["python", "app.py"]
