defmodule Courtbot.Vault do
  @moduledoc false
  use Cloak.Vault, otp_app: :courtbot

  @impl GenServer
  def init(config) do
    case System.get_env("DATABASE_VAULT_KEY") do
      nil -> {:ok, config}
      vault_key ->
        config =
          Keyword.put(config, :ciphers, [
            default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!(vault_key)}
          ])

        {:ok, config}
    end
  end
end

defmodule Courtbot.Encrypted.Binary do
  @moduledoc false
  use Cloak.Fields.Binary, vault: Courtbot.Vault
end
