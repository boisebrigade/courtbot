defmodule CourtbotWeb.Context do
  @behaviour Plug

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _) do
    build_context(conn)
    |> case do
      {:ok, context} ->
        put_private(conn, :absinthe, %{context: context})

      {:error, _reason} ->
        conn

      _ ->
        conn
    end
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, current_user} <- authorize(token) do
      {:ok, %{current_user: current_user}}
    end
  end

  defp authorize(token) do
    Guardian.decode_and_verify(token)
    |> case do
      {:ok, claims} -> return_user(claims)
      {:error, reason} -> {:error, reason}
    end
  end

  defp return_user(claims) do
    Guardian.serializer().from_token(Map.get(claims, "sub"))
    |> case do
      {:ok, resource} -> {:ok, resource}
      {:error, reason} -> {:error, reason}
    end
  end
end
