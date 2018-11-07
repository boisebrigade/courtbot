# Courtbot
[![Build Status](https://travis-ci.org/boisebrigade/Courtbot.svg?branch=development)](https://travis-ci.org/boisebrigade/Courtbot)

Courtbot is a simple web service for subscribing to case hearing details via SMS.

## Development Setup

- Clone the repo: `git clone https://github.com/boisebrigade/Courtbot.git`
- Install Elixir and NodeJS: `# asdf is the preferred version manager`
  - Install [asdf](https://github.com/asdf-vm/asdf#setup)
  - Add Elixir asdf plugin: [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) 
  - Add NodeJS asdf plugin: [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs)
  - Goto where you've cloned the repo and run: `asdf install`
- Copy `.env.example` to `.env`: `cp .env.example .env`
  - Tweak default environment variables as needed
  - Take a look at the [external dependencies](https://github.com/boisebrigade/Courtbot/wiki/External-Dependencies#external-dependencies) as they their credentials will need to be configured for a full development setup 
- Start docker: `docker-compose up -d`
- Run Setup: `mix setup`
- Start Phoenix: `mix phx.server`
  - In development mode, `MIX_ENV` is `dev`, Phoenix will run both `npm run start` and `npm run webpack` for you.

After `mix phx.server` Phoenix will running and you should be able to access the frontend by hitting http://localhost:4001 in your browser of choice. For next steps in setting up Courtbot see [here](https://github.com/boisebrigade/Courtbot/wiki/Configuration) for additional details.

## Documentation
- [Overview](https://github.com/boisebrigade/Courtbot/wiki)
- [External Dependencies](https://github.com/boisebrigade/Courtbot/wiki/External-Dependencies)
- [Configuration](https://github.com/boisebrigade/Courtbot/wiki/Configuration)
- [Deployment](https://github.com/boisebrigade/Courtbot/wiki/Deployment)
- [Code Overview](https://github.com/boisebrigade/Courtbot/wiki/Code-Overview)

## License
ISC, 2018, Code for America

See [LICENSE.md](LICENSE.md)
