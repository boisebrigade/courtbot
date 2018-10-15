defmodule ExCourtbot.Resolver.Importer do
  alias ExCourtbot.{Configuration, Repo, Importer}

  def get_conf(_, _, %{context: %{current_user: _user}}) do
    config =
      Configuration.get([
        "import_kind",
        "import_origin",
        "import_source"
      ])

    {:ok, config}
  end

  def get_conf(_, _, _) do
    {:error, "Requires authentication"}
  end

  def edit_conf(
        %{kind: import_kind, origin: import_origin, source: import_source},
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

  def get_fields(_, _, %{context: %{current_user: _user}}) do
    fields =
      Importer.mapped()
      |> Enum.reduce([], fn field, acc ->
        mapping = Map.take(field, [:index, :pointer, :destination, :kind, :format, :order])

        [mapping | acc]
      end)

    {:ok,
     %{
       fields: fields
     }}
  end

  def get_fields(_, _, _) do
    {:error, "Requires authentication"}
  end

  # FIXME(ts): Check if both pointer and index exist and err out
  def edit_field(
        %{
          index: _index,
          pointer: _pointer,
          destination: _destination,
          kind: _kind,
          format: _format,
          order: _order
        } = params,
        %{context: %{current_user: _user}}
      ) do
    case Repo.insert(Importer.changeset(%Importer{}, params)) do
      %Importer{} = field ->
        {:ok,
         %{
           fields: [
             field
           ]
         }}

      _ ->
        {:error, "Unable to create import field"}
    end
  end

  def test(_, _) do
    {:ok, %{}}
  end
end
