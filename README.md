# ExCourtbot
[![Build Status](https://travis-ci.org/boisebrigade/ExCourtbot.svg?branch=development)](https://travis-ci.org/boisebrigade/ExCourtbot)

ExCourtbot is a simple web service that provides a SMS interface for subscribing to cases for hearing details.

## Development Setup

- Clone the repo
- Install Elixir: preferred to use `asdf`
  - Install [asdf](https://github.com/asdf-vm/asdf#setup)
  - Add Elixir asdf plugin: [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) 
  - Goto where you've cloned the repo and run: `asdf install`
- Copy `.env.example` to `.env`: `cp .env.example .env`
  - Tweak default environment variables as needed
  - Take a look at the [external dependencies](https://github.com/boisebrigade/ExCourtbot/wiki/External-Dependencies#external-dependencies) as they their credentials will need to be configured for a full development setup 
- Start docker: `docker-compose up -d`
- Install dependencies: `env $(cat .env | xargs) mix deps.get`
- Initialize database: `env $(cat .env | xargs) mix ecto.reset`
- Start Phoenix: `env $(cat .env | xargs) mix phx.server`

Upon issuing `mix phx.server` Phoenix is started the REST API will be accessible. Local modifications to code will hot-reload.

## Documentation
Documentation is available [here.](https://github.com/boisebrigade/ExCourtbot/wiki)

## Contributing
Before issuing a PR please run the formatter via `mix format`.

## License
ISC, 2018, Code for America

See [LICENSE.md](LICENSE.md)
