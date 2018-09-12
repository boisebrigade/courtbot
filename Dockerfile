FROM elixir:1.7.2-alpine

ARG MIX_ENV=prod
ENV MIX_ENV ${MIX_ENV}

WORKDIR /opt/app

RUN apk update

RUN mix local.rebar --force
RUN mix local.hex --force

COPY . .

RUN mix deps.get
RUN mix deps.compile
RUN mix compile

RUN mix release --env=${MIX_ENV} --verbose \
  && mv _build/${MIX_ENV}/rel/excourtbot /opt/release

FROM alpine:3.8

RUN apk update && apk --no-cache --update add bash openssl-dev
ENV REPLACE_OS_VARS true
WORKDIR /opt/app
COPY --from=0 /opt/release .
CMD ["/opt/app/bin/excourtbot", "foreground"]
