FROM node:20-alpine3.17 as tailwind

COPY . /app

WORKDIR /app

RUN npm install --verbose -g tailwindcss@v3
RUN npx tailwindcss@v3 -i /app/static/style.css -o /app/build.css --minify

FROM ubuntu as prod

ENV DEV=false

RUN apt-get update && apt-get -y install ucspi-tcp jq file curl bc imagemagick
RUN curl -L https://github.com/vi/websocat/releases/download/v1.8.0/websocat_amd64-linux -o /bin/websocat && chmod +x /bin/websocat

EXPOSE 3000

COPY . /app

COPY --from=tailwind /app/build.css /app/static/tailwind.css

CMD [ "/app/start.sh" ]
