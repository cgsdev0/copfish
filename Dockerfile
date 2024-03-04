FROM ubuntu

ENV DEV false

RUN apt-get update && apt-get install ucspi-tcp

EXPOSE 5125

COPY . /app

CMD [ "/app/start.sh" ]
