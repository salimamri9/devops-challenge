FROM python:3.13-slim
WORKDIR /app
COPY app/app.py .
RUN groupadd -r app && useradd -r -g app app
STOPSIGNAL SIGINT
USER app
EXPOSE 5000
CMD [ "python", "app.py" ]
