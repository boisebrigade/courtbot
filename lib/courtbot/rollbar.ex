defmodule Courtbot.Rollbar do
  @moduledoc false

  @behaviour :gen_event

  @default_format "$message\n"

  alias Courtbot.Integration.Rollbar, as: Api

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state = %{level: min_level}) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    else
      {:ok, state}
    end
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event(:flush, state), do: {:ok, state}

  def handle_info(_, state), do: {:ok, state}

  defp log_event(
         level,
         msg,
         ts,
         md,
         state = %{
           level: min_level,
           access_token: access_token,
           environment: environment,
           metadata: keys
         }
       )
       when access_token != nil and environment != nil do
    # TODO(ts): Filter metadata
    # TODO(ts): Format message according to the provided configuration
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      # Extract miliseconds from the timestamp
      {date, {h, m, s, mi}} = ts

      # Rollbar expects a unix timestamp
      timestamp =
        NaiveDateTime.from_erl!({date, {h, m, s}}, mi)
        # FIXME(ts): Remove hardcoded timezone
        |> DateTime.from_naive!("America/Boise", Tzdata.TimeZoneDatabase)
        |> DateTime.to_unix()

      Api.log(
        %{access_token: access_token, environment: environment},
        %{level: level, message: msg, timestamp: timestamp, metadata: md}
      )
    end

    {:ok, state}
  end

  defp log_event(_level, _msg, _ts, _md, state), do: {:ok, state}

  defp configure(name, opts) do
    state = %{
      name: nil,
      io_device: nil,
      inode: nil,
      format: nil,
      level: nil,
      metadata: nil,
      access_token: nil,
      environment: nil
    }

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    metadata = Keyword.get(opts, :metadata, [])
    format_opts = Keyword.get(opts, :format, @default_format)
    format = Logger.Formatter.compile(format_opts)
    access_token = Keyword.get(opts, :access_token, nil)
    environment = Keyword.get(opts, :environment, nil)

    %{
      state
      | name: name,
        format: format,
        level: level,
        metadata: metadata,
        access_token: access_token,
        environment: environment
    }
  end
end
