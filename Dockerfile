FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY requirements-lock.txt ./
RUN python -m pip install --upgrade pip && python -m pip install --requirement requirements-lock.txt
COPY . .
RUN useradd --create-home --uid 10001 appuser && chown -R appuser:appuser /app && chmod +x /app/docker/entrypoint.sh
USER appuser
EXPOSE 8000
ENTRYPOINT ["/app/docker/entrypoint.sh"]
