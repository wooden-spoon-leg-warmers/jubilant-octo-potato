FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY migrations ./migrations
COPY seeders ./seeders
COPY app.py .

EXPOSE 3000

CMD ["python", "app.py"]