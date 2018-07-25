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

NOTE: These are likely to change. If any steps or URL's become broken or are incorrect please create an issue.

ADDITIONAL NOTE: If you're using a Trial account you will need to verify all phone numbers you'll be testing with manually. If you don't the API will not send the SMS messages. See [this](https://support.twilio.com/hc/en-us/articles/223180048-Adding-a-Verified-Phone-Number-or-Caller-ID-with-Twilio) help doc for additional detail.

#### Setup
There are two parts to configuring Twilio for ExCourtbot. One is the Webhook, this allows ExCourtbot to receive and respond to messages (in the same request.) The other step to configuring Twilio is configuring ExCourtbot to use your Twilio API key. The Twilio API key allows for ExCourtbot to send messages, or reminders, at the interval you set it.

##### Webhook
The Twilio Webhook you setup is how Twilio knows where to route messages and is how you register a phone number.

- Buy a phone number that is SMS capable: https://www.twilio.com/console/phone-numbers/search
- Manage your numbers: https://www.twilio.com/console/phone-numbers/incoming
- Select the number you want ExCourtbot to respond to
  - On the "Configure" tab under the "Messaging" section add your `http://HOST/sms/:locale` to the section "A MESSAGE COMES IN"
    - `HOST` can refer to your Heroku endpoint, the domain ExCourtbot is hosted on or the `ngrok` forwarding address.
    - `:locale` can be omitted, by default it will will assume `en`

You can use [ngrok](https://ngrok.com/) to test your local code with with Twilio.

##### REST API Key

View your [Project Settings](https://www.twilio.com/console/project/settings) for your REST API keys. ExCourtbot needs configured with the two environment variables:
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`

NOTE: When your first setting up ExCourtbot it is recommended to use the TEST credentials provided by Twilio (found in your project settings.)

### Rollbar 
Optionally, for a production environment you can configure Rollbar for error monitoring and logging ExCourtbot. 


#### Setup
NOTE: If you don't have a pre-existing Rollbar account you want to use and are deploying via Heroku, please ignore and follow the Heroku Rollbar setup steps.

If you have a pre-existing Rollbar account then you can create a [new project](https://docs.rollbar.com/docs/projects), Select "Elixir" for your framework, and upon deployment set the `ROLLBAR_ACCESS_TOKEN` environment variable.

## Usage

ExCourtbot intends for as much functionality to be exposed and configurable out of the box as possible. If your case is unsupported via configuration and requires customization please create a new issue.

### Configuration
ExCourtbot is configurable via mix config. Via mix config you can change the import source, import mapping, locale mapping, import/notification schedule, and other court related details.

At a high level ExCourtbot is configurable in the following way:
- Import source and field mapping (CSV, and eventually JSON)
- Case lookup details
- Case validation rules
- Locales
- (Depending on deployment method) Import and notification time

#### Base configuration


```elixir
locales: %{
  "en" => "12083144089"
},
types: %{
  "criminal" => ~r//,
},
court_url: "https://mycourts.idaho.gov/",
import_time: "0 9 * * *",
notify_time: "0 13 * * *"
```
- `locales`
- `types`
- `court_url`
- `import_time`
- `notify_time`


<sup>1</sup>:

#### Importer
A sample importer configuration (to be placed in `config/courtbot.exs`) looks like so:
```elixir
importer: %{
  file: "../test/excourtbot_web/data/boise.csv",
  type:
    {:csv,
     [
       {:has_headers, true},
       {:headers,
        [
          {:date, "%-m/%e/%Y"},
          nil,
          nil,
          nil,
          {:time, "%k:%M:%S"},
          :case_number,
          nil,
          nil,
          nil
        ]},
     ]}
}

```
- `file` or `url`
- `type`
  - `has_headers`
  - `headers`: Is a keyword with `:headers` as the key and an list of mappings to your CSV data.
    - `date` and `time`: Syntax for defining formats can be found [here](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html).

#### CLI

- `mix notify`
- `mix import`

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
  - Required are `SECRET_KEY_BASE`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `DATABASE_URL`
    - `SECRET_KEY_BASE` is a cryptic key you can generate via `mix phx.gen.secret`
    - `TWILIO_ACCOUNT_SID` and`TWILIO_AUTH_TOKEN` require setting up a Twilio account. See [external dependencies](#external-dependencies) for more detail.
    - `DATABASE_URL` should already be provided, and does not need manually set, if you are using the Postgres addon.
- Trigger a build: `git push heroku master`
- Run migrations: `heroku run "MIX_ENV=prod mix ecto.migrate"`
- ExCourtbot should now be running on Heroku.

For convenience fill in the placeholders:
```sh
heroku config:set SECRET_KEY_BASE="<value>"
heroku config:set TWILIO_ACCOUNT_SID="<value>"
heroku config:set TWILIO_AUTH_TOKEN="<value>"
```

##### Rollbar
- Add the rollbar addon: `heroku addons:create rollbar:free`

Upon enabling this addon it will set the `ROLLBAR_ACCESS_TOKEN` environment variable. ExCourtbot is already configured to consume this.

##### Scheduler
- Add scheduler as an addon: `heroku addons:create scheduler:standard`

Upon enabling this addon you'll need to configure it so that ExCourtbot can at an interval pull in new data and notify subscribers of upcoming hearings.
- Open scheduler settings: `heroku addons:open scheduler`
- Click "Add new job"
  - $`mix notify`; _Dyno Size_: Free, _Frequency_: Daily, _Next Due_: 19:00 UTC
    - I'd recommend converting 1pm into your local timezone and using it in place of 19:00 UTC.
  - $`mix import`; _Dyno Size_: Free, _Frequency_: Daily, _Next Due_: 15:00 UTC
    - I'd recommend converting 9am into your local timezone and using it in place of 15:00 UTC.
    - NOTE: Import has to occur before notify or else you will be sending stale hearing information. 


#### Updating Heroku after you've made changes
- Add your changes: `git add <files>`
- Commit the work: `git commit -m "Explain your changes"`
- Push to Heroku: `git push heroku master`

### Docker
- Build the docker image: `env $(cat .env.production | xargs) docker build`

## License
ISC, 2018, Code for America

See [LICENSE.md](LICENSE.md)
