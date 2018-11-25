defmodule Courtbot.Resolver.Importer do
  alias Courtbot.{Configuration, Repo, Importer}

  def get(_, _, %{context: %{current_user: _user}}) do
    config =
      Configuration.get([
        "import_kind",
        "import_origin",
        "import_source"
      ])

    fields =
      Importer.mapped()
      |> Enum.reduce([], fn field, acc ->
        mapping = Map.take(field, [:index, :pointer, :destination, :kind, :format, :order])

        [mapping | acc]
      end)
      |> Enum.sort(&(&1.index < &2.index))

    {:ok,
     %{
       kind: config.import_kind,
       origin: config.import_origin,
       source: config.import_source,
       fields: fields
     }}
  end

  def get(_, _, _) do
    {:error, "Requires authentication"}
  end

  def edit(
        %{kind: import_kind, origin: import_origin, source: import_source, fields: fields},
        %{context: %{current_user: _user}}
      ) do
    # TODO(ts): Validate kind, origin, and source

    conf = [
      %{
        name: "import_kind",
        value: import_kind,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "import_origin",
        value: import_origin,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "import_source",
        value: import_source,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      }
    ]

    Repo.insert_all(Configuration, conf, on_conflict: :replace_all, conflict_target: :name)

    {:ok,
     [
       %{
         kind: import_kind,
         origin: import_origin,
         source: import_source
       }
     ]}
  end

  def edit(_, _, _) do
    {:error, "Requires authentication"}
  end

  def test(%{kind: kind, origin: origin, source: source} = input, %{
        context: %{current_user: _user}
      }) do
    # TODO(ts): Error handling

    headers = Courtbot.test_import(kind, origin, source)
    {:ok, %{headers: headers}}
  end
end
