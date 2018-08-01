FROM elixir:1.6-alpine

EXPOSE 4000
ENV PORT=4000

COPY . .
RUN \
    mix do deps.get, deps.compile && \
    mix do compile, release --verbose --env=prod && \
    mkdir -p /opt/myapp/log && \
    cp rel/excourtbot/releases/0.0.1/excourtbot.tar.gz /opt/excourtbot/ && \
    cd /opt/excourtbot && \
    tar -xzf excourtbot.tar.gz && \
    rm excourtbot.tar.gz && \
    rm -rf /opt/app/* && \
    chmod -R 777 /opt/app && \
    chmod -R 777 /opt/excourtbot

WORKDIR /opt/excourtbot

CMD ./bin/excourtbot foreground
