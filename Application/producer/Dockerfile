FROM python:3.10-slim
WORKDIR /app
COPY app.py /app.py
RUN pip install kafka-python requests

ENTRYPOINT ["python", "-u", "/app.py"]
