FROM python:3.11-slim

WORKDIR /app

COPY app.py .
COPY index.html .
COPY requirements.txt .

RUN pip install -r requirements.txt

CMD ["python", "app.py"]
