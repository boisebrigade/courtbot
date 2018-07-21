# ExCourtbot
ExCourtbot is a simple web service that provides a SMS interface for subscribing to cases for hearing details.

## Objective:
ExCourtbox seeks to solve the following problems:
- **Reminders.** If a case requires a court appearance, the app allows users to sign up for reminders, served 24 hours in advance of the case.
- **Payable Prompt.** If a case can be paid immediately, the app offers a phone number and link to begin payment.
- **Queued Cases.** If a case isn't in the system (usually because it takes two weeks for paper citations to be put into the computer), the app allows users to get information when it becomes available. The app continues checking each day for up to 16 days and sends the case information when found (or an apology if not).

## Development Setup

- Clone the repo
- Install Elixir: preferred to use `asdf`
  - Install [asdf](https://github.com/asdf-vm/asdf#setup)
  - Add Elixir asdf plugin: [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) 
  - Goto where you've cloned the repo and run: `asdf install`
- Copy `.env.example` to `.env.dev`: `cp .env.example .env.dev`
  - Tweak default environment variables as needed
  - Take a look at the [external dependencies](#external-dependencies) as they their credentials will need to be configured for a full development setup 
- Start docker: `docker-compose up -d`
- Install dependencies: `env $(cat .env.dev | xargs) mix deps.get`
- Initialize database: `env $(cat .env.dev | xargs) mix ecto.reset`
- Start Phoenix: `env $(cat .env.dev | xargs) mix phx.server`

Once Phoenix is started the REST API will be accessible. Any changes to `config/*` require Phoenix to be restarted (Elixir is a compiled language afterall.) Everything else should hot reload.

### Testing
- Start docker: `docker-compose up -d`
- Copy `.env.example` to `.env.test`: `cp .env.example .env.test`
  - Tweak default environment variables as needed.
  - By default the docker-compose will create a test database named `excourtbot_test` make sure to update the `DATABASE_URL` accordingly.
- Run tests: `env $(cat .env.test | xargs) mix test`
- Test watch: `env $(cat .env.test | xargs) mix test.watch`

## External Dependencies

External dependencies try to be limited as much as possible as the least amount of 

### Twilio
Required, Twilio is the service ExCourtbot uses to send (and receive) SMS.

NOTE: these are likely to change. If any steps or URL's become broken or are incorrect please create an issue.

#### Setup

##### Webhook
The Twilio Webhook you setup is how Twilio knows where to route messages and is how you register a phone number.

- Buy a phone number that is SMS capable: https://www.twilio.com/console/phone-numbers/search
- Manage your numbers: https://www.twilio.com/console/phone-numbers/incoming
- Select the number you want ExCourtbot to respond to
  - On the "Configure" tab under the "Messaging" section add your `HOST` to the section "A MESSAGE COMES IN"
    - `HOST` can refer to your Heroku endpoint, the domain ExCourtbot is hosted on or the `ngrok` forwarding address.

You can use [ngrok](https://ngrok.com/) to test  

##### API Key


### Rollbar 
Optionally, for a production environment you can configure Rollbar for error monitoring and logging ExCourtbot. 


#### Setup

## Usage

ExCourbot intends for as much functionality to be exposed and configurable out of the box as possible. If your case is unsupported via configuration and requires customization please create a new issue.

### Configuration


#### ExCourtbot

#### Importer

### Customization


#### Custom Authentication

## Deployment
ExCourtbot is designed to be deployed as a docker container or on Heroku. Please create an issue if you have additional requirements which may not be met with either solution.

NOTE: Deployment of Elixir is different than say Ruby or Node. Elixir is a compiled lanaguage and the primary form of configuration in Elixir is `mix config`, which requires variables to be set at build time and not in the production's box environment. The deployment steps below does factor this in.


### Heroku
This is an abbreviated and customized form of this [tutorial](https://hexdocs.pm/phoenix/heroku.html).

#### Account
- Signup for Heroku account: https://signup.heroku.com/
- Install Heroku cli: https://devcenter.heroku.com/articles/heroku-cli
  - Login with the CLI tool: `heroku login`

#### Initial Setup
- Create a Heroku project with the Elixir Buildpack: `heroku create --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"`
- Add Postgres as a Heroku addon: `heroku addons:create heroku-postgresql:hobby-dev`
  - Note: Doing this will automatically set the `DATABASE_URL` environment variable for you.
- Set Environment variables: `heroku config:set VARIABLE="value"`
  - Required are `HOST`, `SECRET_KEY_BASE`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `DATABASE_URL`
    - `HOST` is the Heroku application name and`herokuapp.com`: i.e. `<heroku application>.herokuapp.com`
    - `SECRET_KEY_BASE` is a cryptic key you can generate via `mix phx.gen.secret`
    - `TWILIO_ACCOUNT_SID` and`TWILIO_AUTH_TOKEN` require setting up a Twilio account. See [external dependencies](#external-dependencies) for more detail.
    - `DATABASE_URL` should already be provided if you are using the Postgres addon.
- Trigger a build: `git push heroku master`
- Run migrations: `heroku run "MIX_ENV=prod mix ecto.migrate"`
- ExCourtbot should now be running on Heroku.

For convenience fill in the placeholders:
```sh
heroku config:set HOST="<value>"
heroku config:set SECRET_KEY_BASE="<value>"
heroku config:set TWILIO_ACCOUNT_SID="<value>"
heroku config:set TWILIO_AUTH_TOKEN="<value>"
```

##### Rollbar
- Add the rollbar addon: `heroku addons:create rollbar:free` 

##### Scheduler

- Add scheduler as an addon: `heroku addons:create scheduler:standard`


#### Updating Heroku after you've made changes
- Add your changes: `git add <files>`
- Commit the work: `git commit -m "Explain your changes"`
- Push to Heroku: `git push heroku master`

### Docker
- Build the docker image: `env $(cat .env.production | xargs) docker build`


## License
ISC, 2018, Code for America

See [LICENSE.md](LICENSE.md)
