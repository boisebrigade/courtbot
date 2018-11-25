defmodule Courtbot.User do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  alias Courtbot.{Repo, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:user_name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:jwt, :string, virtual: true)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:user_name, :password])
  end

  def authenticate(params) do
    user = Repo.get_by(User, user_name: params.user_name)

    case check_password(user, params.password) do
      true -> {:ok, user}
      _ -> {:error, "Invalid credentials"}
    end
  end

  def reset_password(user, password) do
    from(
      u in User,
      where: u.user_name == ^user
    )
    |> Repo.one()
    |> User.changeset(%{user_name: user, password: password})
    |> hash_password()
    |> Repo.update()
  end

  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> Comeonin.Bcrypt.checkpw(password, user.password_hash)
    end
  end

  def change_details(user, params \\ %{}) do
    user
    |> cast(params, [:password])
    |> validate_password
    |> Repo.update()
  end

  defp validate_password(changeset) do
    if get_change(changeset, :password) do
      changeset
      |> validate_length(:password, min: 7)
      |> hash_password
    else
      changeset
    end
  end

  def hash(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)
    hashed_password = hash(password)

    changeset
    |> put_change(:password_hash, hashed_password)
  end
end
