FROM ubuntu

ENV DEV false

RUN apt-get update && apt-get -y install ucspi-tcp jq file

EXPOSE 5125

COPY . /app

CMD [ "/app/start.sh" ]
