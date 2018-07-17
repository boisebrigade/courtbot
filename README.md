# ExCourtbot
ExCourtbot is a simple web service that provides a SMS interface for subscribing to cases for hearing details.

# Overview:
Specifically, the twilio features include:

- **Payable Prompt.** If a case can be paid immediately, the app offers a phone number and link to begin payment.
- **Reminders.** If a case requires a court appearance, the app allows users to sign up for reminders, served 24 hours in advance of the case.
- **Queued Cases.** If a case isn't in the system (usually because it takes two weeks for paper citations to be put into the computer), the app allows users to get information when it becomes available. The app continues checking each day for up to 16 days and sends the case information when found (or an apology if not).

## Development Setup

- Clone the repo
- Install Elixir: preferred to use `asdf`
  - Install [asdf](https://github.com/asdf-vm/asdf#setup)
  - Add Elixir asdf plugin: [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) 
  - Goto where you've cloned the repo and run: `asdf install`
- Copy `.env.example` to `.env`: `cp .env.example .env`
- Tweak default environment variables as needed
- Start docker: `env $(cat .env | xargs) docker-compose up -d`
- Install dependencies: `mix deps.get`
- Initialize database: `mix ecto.reset`
- Start Phoenix: `mix phx.server`

### Testing
- Run tests: `mix test`


Any changes to `config/*` require Phoenix to be restarted (Elixir is a compiled language afterall.) Everything else should hot reload.

## External Dependencies



### Twilio

### Sentry 
Optionally, for a production environment you can configure ExCourtbot 

## Deployment
ExCourtbot is designed to be deployed 