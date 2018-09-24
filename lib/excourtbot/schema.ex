defmodule ExCourtbot.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema.Notation, :modern
  use Absinthe.Relay.Schema, :modern

  node interface do
    resolve_type(fn
      _, _ ->
        :conf
    end)
  end

  node object(:conf) do
    field(:twilio_sid, :string)
    field(:twilio_token, :string)

    field(:rollbar_token, :string)
  end

  query do
    field :configuration, :conf do
      resolve(&ExCourtbot.Resolver.Configuration.get/3)
    end
  end

  mutation do
    payload field(:user_login) do
      input do
        field(:user_name, non_null(:string))
        field(:password, non_null(:string))
      end

      output do
        field(:jwt, :string)
      end

      resolve(&ExCourtbot.Resolver.User.login/2)
    end

    payload field(:user_edit) do
      input do
        field(:current_password, non_null(:string))
        field(:password, :string)
        field(:user_name, :string)
      end

      output do
        field(:id, non_null(:id))
        field(:jwt, :string)
      end

      resolve(&ExCourtbot.Resolver.User.edit/2)
    end

    payload field(:conf) do
      input do
        field(:twilio_sid, :string)
        field(:twilio_token, :string)

        field(:rollbar_token, :string)
      end

      output do
        field(:twilio_sid, :string)
        field(:twilio_token, :string)

        field(:rollbar_token, :string)
      end
    end

  end
end
