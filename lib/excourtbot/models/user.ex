defmodule ExCourtbot.User do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  alias ExCourtbot.{Repo, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:user_name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:jwt, :string, virtual: true)

    timestamps()
  end

  def authenticate(params) do
    user = Repo.get_by(User, user_name: params.user_name)

    case check_password(user, params.password) do
      true -> {:ok, user}
      _ -> {:error, "Invalid credentials"}
    end
  end


  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> Comeonin.Bcrypt.checkpw(password, user.password_hash)
    end
  end

end
