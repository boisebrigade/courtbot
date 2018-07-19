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
- Copy `.env.dev.example` to `.env.dev`: `cp .env.dev.example .env.dev`
  - Tweak default environment variables as needed
  - Take a look at the [external dependencies]() as they their credentials will need to be configured for a full development setup 
- Start docker: `docker-compose up -d`
- Install dependencies: `env $(cat .env.dev | xargs) mix deps.get`
- Initialize database: `env $(cat .env.dev | xargs) mix ecto.reset`
- Start Phoenix: `env $(cat .env.dev | xargs) mix phx.server`

Once Phoenix is started the REST API will be accessible. Any changes to `config/*` require Phoenix to be restarted (Elixir is a compiled language afterall.) Everything else should hot reload.

### Testing
- Start docker: `docker-compose up -d`
- Copy `.env.test.example` to `.env.test`: `cp .env.test.example .env.test`
  - Tweak default environment variables as needed.
  - By default the docker-compose will create a test database named `excourtbot_test` make sure to 
- Run tests: `env $(cat .env.test | xargs) mix test`
- Test watch: `env $(cat .env.test | xargs) mix test.watch`




## External Dependencies

External dependencies try to be limited as much as possible as the least amount of 

### Twilio
Required, Twilio is the service ExCourtbot uses to send (and receive) SMS.




#### Setup
- A phone number should be secured.
- API Key
- 


- A webhook should be configured.

Use ngrok locally to test webhook.

### Sentry 
Optionally, for a production environment you can configure Sentry for error monitoring and logging ExCourtbot. 


#### Setup

## Usage

ExCourbot intends for as much functionality to be exposed and configurable out of the box as possible. If your case is unsupported via configuration and requires customization please create a new issue.

### Configuration
TODO: Document configuration

### Customization
- Tesla

## Deployment
ExCourtbot is designed to be deployed as a docker container or on Heroku. Please create an issue if you have additional requirements which may not be met with either solution.

NOTE: Deployment of Elixir is different than say Ruby or Node. Elixir is a compiled lanaguage and the primary form of configuration in Elixir is `mix config`, which requires variables to be set at build time and not in the production's box environment. The deployment steps below does factor this in.


### Heroku
This is an abbreviated and customized form of this [tutorial](https://hexdocs.pm/phoenix/heroku.html).

#### Account
- Signup for Heroku account: https://signup.heroku.com/
- Install Heroku cli: https://devcenter.heroku.com/articles/heroku-cli
  - Login with the CLI tool: `heroku login`
  - Create a Heroku application: `heroku create`
  
#### Initial Setup
- Use Elixir Buildpack: `heroku create --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"`
  - There are some details that could be configured such as the Erlang and Elixir version, details found [here](https://github.com/HashNuke/heroku-buildpack-elixir#configuration).

#### Deployment


### Docker
- Build the docker image: `env $(cat .env.production | xargs) docker build`


## License

