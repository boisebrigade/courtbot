defmodule Courtbot.Vault do
  use Cloak.Vault, otp_app: :courtbot
  @impl Cloak.Vault

  def init(config) do
    config =
      if config[:ciphers] do
        config
      else
        cloak_encryption_key =
          System.get_env("CLOAK_ENCRYPTION_KEY") |> Base.decode64!() ||
            raise "expected the CLOAK_ENCRYPTION_KEY environment variable to be set"

        config
        |> Keyword.put(
          :ciphers,
          default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: cloak_encryption_key}
        )
      end

    {:ok, config}
  end
end

defmodule Courtbot.Encrypted.Binary do
  use Cloak.Fields.Binary, vault: Courtbot.Vault
end
