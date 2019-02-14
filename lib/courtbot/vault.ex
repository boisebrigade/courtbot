defmodule Courtbot.Vault do
  use Cloak.Vault, otp_app: :courtbot
end

defmodule Courtbot.Encrypted.Binary do
  use Cloak.Fields.Binary, vault: Courtbot.Vault
end
