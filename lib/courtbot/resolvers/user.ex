defmodule Courtbot.Resolver.User do
  alias Courtbot.User

  def login(params, _) do
    with {:ok, user} <- User.authenticate(params),
         {:ok, jwt, _} <- Guardian.encode_and_sign(user, :access),
         do: {:ok, %{user | jwt: jwt}}
  end

  def edit(params, %{context: %{current_user: user}}) do
    User.authenticate(%{email: user.email, password: params.current_password})
    |> case do
      {:ok, _} -> User.change_details(user, params)
      {:error, _} -> {:error, "Current password must be correct"}
    end
  end

  def edit(_, _context) do
    {:error, "Requires authentication"}
  end
end
