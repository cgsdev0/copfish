FROM ubuntu

ENV DEV false

RUN apt-get update && apt-get -y install ucspi-tcp jq file curl bc
RUN curl https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl -o /bin/websocat && chmod +x /bin/websocat

EXPOSE 5125

COPY . /app

CMD [ "/app/start.sh" ]
