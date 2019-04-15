defmodule Courtbot.Vault do
  @moduledoc false
  use Cloak.Vault, otp_app: :courtbot
end

defmodule Courtbot.Encrypted.Binary do
  @moduledoc false
  use Cloak.Fields.Binary, vault: Courtbot.Vault
end
