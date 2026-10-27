FROM python:3.13-slim
WORKDIR /app
COPY app/app.py .
RUN groupadd -r -g 10001 app && useradd -r -u 10001 -g app app
STOPSIGNAL SIGINT
USER 10001
EXPOSE 5000
CMD [ "python", "app.py" ]
