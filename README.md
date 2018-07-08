# ExCourtbot
Courtbot is a simple web service for handling court case data. It offers a basic HTTP endpoint for integration with websites, and a set of advanced twilio workflows to handle text-based lookup.

Specifically, the twilio features include:

- **Payable Prompt.** If a case can be paid immediately, the app offers a phone number and link to begin payment.
- **Reminders.** If a case requires a court appearance, the app allows users to sign up for reminders, served 24 hours in advance of the case.
- **Queued Cases.** If a case isn't in the system (usually because it takes two weeks for paper citations to be put into the computer), the app allows users to get information when it becomes available. The app continues checking each day for up to 16 days and sends the case information when found (or an apology if not).

### Setup
- Copy `.env.example` to `.env`: `cp .env.example .env`
- Tweak default env's as needed
- Start docker: `env $(cat .env | xargs) docker-compose up -d`
- Install deps: `docker-compose exec elixir mix deps.get`
- Initialize database: `docker-compose exec elixir mix ecto.setup`
- Start Phoenix: `docker-compose exec elixir mix phx.server`

Any changes to `config/*` require Phoenix to be restarted (Elixir is a compiled language afterall.) Everything else should hot reload.

### Dependencies

#### Twilio

#### Rollbar



### Deployment



### Local Development
- Tests auto reload: `docker-compose exec elixir mix test.watch`