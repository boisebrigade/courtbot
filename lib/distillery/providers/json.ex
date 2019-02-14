defmodule Distillery.Json.Provider do
  use Mix.Releases.Config.Provider

  def init([config_path]) do
    # Helper which expands paths to absolute form
    # and expands env vars in the path of the form `${VAR}`
    # to their value in the system environment
    config_path = Provider.expand_path(config_path)
    # All applications are already loaded at this point
    if File.exists?(config_path) do
      config_path
      |> Jason.decode!
      |> to_keyword()
      |> persist()
    else
      :ok
    end
  end

  defp to_keyword(config) when is_map(config) do
    for {k, _v} <- config do
      k = String.to_atom(k)
      {k, to_keyword(config)}
    end
  end
  defp to_keyword(config), do: config

  defp persist(config) when is_map(config) do
    config = to_keyword(config)
    for {app, app_config} <- config do
      base_config = Application.get_all_env(app)
      merged = merge_config(base_config, app_config)
      for {k, v} <- merged do
        Application.put_env(app, k, v, persistent: true)
      end
    end
    :ok
  end

  defp merge_config(a, b) do
    Keyword.merge(a, b, fn _, app1, app2 ->
      Keyword.merge(app1, app2, &merge_config/3)
    end)
  end
  defp merge_config(_key, val1, val2) do
    if Keyword.keyword?(val1) and Keyword.keyword?(val2) do
      Keyword.merge(val1, val2, &merge_config/3)
    else
      val2
    end
  end
end
