FROM python:3.10-slim
WORKDIR /app
COPY main.py .
RUN pip install vaderSentiment
CMD ["python", "main.py"]