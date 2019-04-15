# Courtbot
[![Build Status](https://travis-ci.org/boisebrigade/courtbot.svg?branch=development)](https://travis-ci.org/boisebrigade/courtbot)

Courtbot is a simple web service for subscribing to case hearing details via SMS.

## Development Setup

- Clone the repo: `git clone https://github.com/boisebrigade/courtbot.git`
- Install Elixir: `# asdf is the preferred version manager`
  - Install [asdf](https://github.com/asdf-vm/asdf#setup)
  - Add Elixir asdf plugin: [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) 
  - Goto where you've cloned the repo and run: `asdf install`
- Start docker: `docker-compose up -d`
- Run Setup: `mix setup`
- Start Phoenix: `mix phx.server`

After `mix phx.server` Phoenix will running and for next steps in setting up Courtbot see [here](https://github.com/boisebrigade/Courtbot/wiki/Configuration) for additional details.

## Documentation
- [Overview](https://github.com/boisebrigade/Courtbot/wiki)
- [External Dependencies](https://github.com/boisebrigade/Courtbot/wiki/External-Dependencies)
- [Configuration](https://github.com/boisebrigade/Courtbot/wiki/Configuration)
- [Deployment](https://github.com/boisebrigade/Courtbot/wiki/Deployment)
- [Code Overview](https://github.com/boisebrigade/Courtbot/wiki/Code-Overview)

## License
ISC, 2018, Code for America

See [LICENSE.md](LICENSE.md)
