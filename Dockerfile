FROM elixir:1.7.2-alpine

ARG MIX_ENV=prod
ARG APP_VERSION=0.0.1
ENV COOKIE="courtbot"
ENV POOL_SIZE=10
ENV HOST=localhost
ENV PORT=4000
ENV MIX_ENV ${MIX_ENV}
ENV APP_VERSION ${APP_VERSION}

WORKDIR /opt/app

RUN apk update

RUN mix local.rebar --force
RUN mix local.hex --force

COPY . .

RUN mix deps.get
RUN mix deps.compile
RUN mix compile

RUN mix release --env=${MIX_ENV} --verbose \
  && mv _build/${MIX_ENV}/rel/excourtbot /opt/release \
  && mv /opt/release/bin/excourtbot /opt/release/bin/start_server

FROM alpine:3.8

RUN apk update && apk --no-cache --update add bash openssl-dev
ENV REPLACE_OS_VARS true
WORKDIR /opt/app
COPY --from=0 /opt/release .
CMD ["/opt/app/bin/start_server", "foreground"]
