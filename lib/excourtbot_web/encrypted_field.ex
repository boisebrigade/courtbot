defmodule ExCourtbotWeb.EncryptedField do
  @behaviour Ecto.Type

  def type, do: :binary

  def cast(value) do
    {
      :ok,
      value
      |> to_string
    }
  end

  def dump(value) do
    data_encryption =
      System.get_env("SECRET_KEY_BASE") ||
        raise "expected the SECRET_KEY_BASE environment variable to be set"

    [iv: iv, ciphertext: ciphertext] = AES256.encrypt(value, data_encryption)

    {
      :ok,
      iv <> ciphertext
    }
  end

  def load(value) do
    <<iv::binary-16, ciphertext::binary>> = value

    data_encryption =
      System.get_env("SECRET_KEY_BASE") ||
        raise "expected the SECRET_KEY_BASE environment variable to be set"

    {
      :ok,
      AES256.decrypt(ciphertext, data_encryption, iv)
    }
  end
end
