FROM ubuntu

ENV DEV false

RUN apt-get update && apt-get -y install ucspi-tcp jq file curl bc
RUN curl https://github.com/vi/websocat/releases/download/v1.8.0/websocat_amd64-linux -o /bin/websocat && chmod +x /bin/websocat

EXPOSE 5125

COPY . /app

CMD [ "/app/start.sh" ]
