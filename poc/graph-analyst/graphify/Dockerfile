FROM python:3.12-slim

WORKDIR /data

RUN pip install --no-cache-dir "graphifyy[mcp]"

EXPOSE 8080

ENTRYPOINT ["python", "-m", "graphify.serve", "/data/graph.json", "--transport", "http", "--host", "0.0.0.0", "--port", "8080"]
