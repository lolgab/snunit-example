FROM nginx/unit:1.24.0-minimal

RUN apt-get update && apt-get install -y libuv1

COPY /config.json /docker-entrypoint.d/
COPY /www /www
COPY example/js/target/scala-2.13/example-fastopt.js /www/index.js
RUN chmod -R 777 /www
COPY example/native/target/scala-2.13/example-out /app/example

EXPOSE 8080
