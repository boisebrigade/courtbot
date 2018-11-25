defmodule Courtbot.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema.Notation, :modern
  use Absinthe.Relay.Schema, :modern

  node interface do
    resolve_type(fn
      _, _ ->
        :conf
    end)
  end

  node object(:dashboard) do
    field(:twilio, non_null(:boolean))
    field(:rollbar, non_null(:boolean))
    field(:locales, non_null(:boolean))
    field(:importer, non_null(:boolean))
  end

  node object(:conf) do
    field(:twilio_sid, non_null(:string))
    field(:twilio_token, non_null(:string))

    field(:rollbar_token, non_null(:string))

    field(:import_time, non_null(:string))
    field(:notification_time, non_null(:string))

    field(:timezone, non_null(:string))

    field(:court_url, non_null(:string))
  end

  object(:csv) do
    field(:has_headers, :boolean)
    field(:delimiter, :string)
  end

  union :settings do
    types [:csv]
    resolve_type fn
      _, _ -> :csv
    end
  end

  node object(:importer) do
    field(:kind, non_null(:string))
    field(:origin, non_null(:string))
    field(:source, non_null(:string))
    field(:settings, :settings)
    field(:headers, list_of(non_null(:string)))
    field(:fields, list_of(non_null(:field)))
  end

  object(:field) do
    field(:index, :integer)
    field(:pointer, :string)
    field(:destination, :string)
    field(:kind, :string)
    field(:format, :string)
  end


  input_object(:input_field) do
    field(:index, :integer)
    field(:pointer, non_null(:string))
    field(:destination, :string)
    field(:kind, non_null(:string))
    field(:format, non_null(:string))
  end

  query do
    field :dashboard, :dashboard do
      resolve(&Courtbot.Resolver.Dashboard.get/3)
    end

    field :configuration, :conf do
      resolve(&Courtbot.Resolver.Configuration.get/3)
    end

    field :importer, :importer do
      resolve(&Courtbot.Resolver.Importer.get/3)
    end
  end

  mutation do
    payload field(:user_login) do
      input do
        field(:user_name, non_null(:string))
        field(:password, non_null(:string))
      end

      output do
        field(:jwt, non_null(:string))
      end

      resolve(&Courtbot.Resolver.User.login/2)
    end

    payload field(:user_edit) do
      input do
        field(:current_password, non_null(:string))
        field(:password, non_null(:string))
        field(:user_name, non_null(:string))
      end

      output do
        field(:id, non_null(:id))
        field(:jwt, non_null(:string))
      end

      resolve(&Courtbot.Resolver.User.edit/2)
    end

    payload field(:set_configuration) do
      input do
        field(:twilio_sid, non_null(:string))
        field(:twilio_token, non_null(:string))

        field(:rollbar_token, non_null(:string))

        field(:import_time, non_null(:string))
        field(:notification_time, non_null(:string))

        field(:timezone, non_null(:string))

        field(:court_url, non_null(:string))
      end

      output do
        field(:twilio_sid, non_null(:string))
        field(:twilio_token, non_null(:string))

        field(:rollbar_token, non_null(:string))

        field(:import_time, non_null(:string))
        field(:notification_time, non_null(:string))

        field(:timezone, non_null(:string))

        field(:court_url, non_null(:string))
      end

      resolve(&Courtbot.Resolver.Configuration.edit/2)
    end

    payload field(:set_importer) do
      input do
        field(:kind, non_null(:string))
        field(:origin, non_null(:string))
        field(:source, non_null(:string))
      end

      output do
        field(:mappable, list_of(:string))
        field(:fields, :string)
      end

      resolve(&Courtbot.Resolver.Importer.edit/2)
    end

    payload field(:test_import) do
      input do
        field(:kind, non_null(:string))
        field(:origin, non_null(:string))
        field(:source, non_null(:string))
      end

      output do
        field(:headers, list_of(non_null(:string)))
      end

      resolve(&Courtbot.Resolver.Importer.test/2)
    end
  end
end
