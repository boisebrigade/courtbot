FROM elixir:1.6-alpine

EXPOSE 4000
ENV PORT=4000 \
    MIX_ENV=prod

COPY . .
RUN \
    mix do deps.get, deps.compile && \
    mix do compile, release --verbose --env=prod && \
    mkdir -p /opt/myapp/log && \
    cp rel/myapp/releases/0.1.0/myapp.tar.gz /opt/myapp/ && \
    cd /opt/myapp && \
    tar -xzf myapp.tar.gz && \
    rm myapp.tar.gz && \
    rm -rf /opt/app/* && \
    chmod -R 777 /opt/app && \
    chmod -R 777 /opt/myapp

WORKDIR /opt/myapp

CMD ./bin/myapp foreground
