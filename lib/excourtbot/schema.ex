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
  end

  node object(:importer_conf) do
    field(:kind, non_null(:string))
    field(:origin, non_null(:string))
    field(:source, non_null(:string))
  end

  object(:field) do
    field(:index, :integer)
    field(:pointer, :string)
    field(:destination, :string)
    field(:kind, :string)
    field(:format, :string)
    field(:order, :integer)
  end

  node object(:importer_field) do
    field(:fields, non_null(list_of(:field)))
  end

  query do
    field :dashboard, :dashboard do
      resolve(&ExCourtbot.Resolver.Dashboard.get/3)
    end

    field :configuration, :conf do
      resolve(&ExCourtbot.Resolver.Configuration.get/3)
    end

    field :importer_configuration, :importer_conf do
      resolve(&ExCourtbot.Resolver.Importer.get_conf/3)
    end

    field :importer_fields, :importer_field do
      resolve(&ExCourtbot.Resolver.Importer.get_fields/3)
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

      resolve(&ExCourtbot.Resolver.User.login/2)
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

      resolve(&ExCourtbot.Resolver.User.edit/2)
    end

    payload field(:set_configuration) do
      input do
        field(:twilio_sid, non_null(:string))
        field(:twilio_token, non_null(:string))

        field(:rollbar_token, non_null(:string))
      end

      output do
        field(:twilio_sid, non_null(:string))
        field(:twilio_token, non_null(:string))

        field(:rollbar_token, non_null(:string))
      end

      resolve(&ExCourtbot.Resolver.Configuration.edit/2)
    end

    payload field(:set_importer_configuration) do
      input do
        field(:kind, non_null(:string))
        field(:origin, non_null(:string))
        field(:source, non_null(:string))
      end

      output do
        field(:mappable, list_of(:string))
        field(:fields, :string)
      end

      resolve(&ExCourtbot.Resolver.Importer.edit_conf/2)
    end

    payload field(:set_importer_field) do
      input do
        field(:index, :integer)
        field(:pointer, :string)
        field(:destination, :string)
        field(:kind, :string)
        field(:format, :string)
      end

      output do
        field(:fields, non_null(list_of(:field)))
      end

      resolve(&ExCourtbot.Resolver.Importer.edit_field/2)
    end

    payload field(:test_import) do
      output do
        field(:kind, :string)
        field(:origin, :string)
        field(:source, :string)
        field(:rows, list_of(:string))
      end
    end
  end
end
