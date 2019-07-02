defmodule CourtbotWeb.Twilio.Session do
  @behaviour Plug.Session.Store

  alias Courtbot.Sessions
  alias Courtbot.Repo

  import Ecto.Query

  # TODO(ts): Verify signing_salt
  def init(opts) do
    Keyword.put_new(opts, :max_age, 60)
  end

  def get(_conn, sid, opts) do
    with {:ok, identifier} <-
           Phoenix.Token.verify(CourtbotWeb.Endpoint, opts[:signing_salt], sid,
             max_age: opts[:max_age]
           ),
         session = %Sessions{} = Repo.one(from(s in Sessions, where: s.id == ^sid)) do
      %{data: data} =
        Sessions.changeset(session, %{expires_at: expires(opts[:max_age])})
        |> Repo.update!()

      {identifier, data}
    else
      _ -> {nil, %{}}
    end
  end

  def put(_conn = %Plug.Conn{params: %{"From" => from, "To" => to}}, nil, data, opts) do
    identifier = String.replace("#{from}#{to}", "+", "")

    token = Phoenix.Token.sign(CourtbotWeb.Endpoint, opts[:signing_salt], identifier)

    put_new(%{id: token, data: data, expires_at: expires(opts[:max_age])}, opts)
  end

  def put(_conn, sid, data, opts) do
    with {:ok, identifier} <-
           Phoenix.Token.verify(CourtbotWeb.Endpoint, opts[:signing_salt], sid,
             max_age: opts[:max_age]
           ),
         session = %Sessions{} = Repo.one(from(s in Sessions, where: s.id == ^sid)) do
      session
      |> Sessions.changeset(%{data: data, expires_at: expires(opts[:max_age])})
      |> Repo.update!()

      identifier
    else
      _ -> nil
    end
  end

  def delete(_conn, sid, opts) do
    with {:ok, identifier} <-
           Phoenix.Token.verify(CourtbotWeb.Endpoint, opts[:signing_salt], sid,
             max_age: opts[:max_age]
           ) do
      Repo.delete_all(from(s in Sessions, where: s.id == ^identifier))
    end

    :ok
  end

  defp expires(max_age) do
    Timex.add(Timex.now("UTC"), Timex.Duration.from_seconds(max_age))
  end

  defp put_new(data = %{id: id}, _opts) do
    %Sessions{}
    |> Sessions.changeset(data)
    |> Repo.insert!()

    id
  end
end
