defmodule ExCourtbot.Resolver.Importer do

  alias ExCourtbot.{Configuration, Repo}

  import Ecto.Query

  def get_conf(%{}, _, _) do
    Repo.all(Configuration.get_conf(["import_kind", "import_origin", "import_source"]))
    |> IO.inspect
#
#    query =
#      Enum.map(fields, fn f ->
#        from(c in Configuration,
#          where: c.name == ^f,
#          select: [c.name, c.value]
#        )
#      end)
#      |> IO.inspect
#      |> Repo.one
#      |> IO.inspect

    {:ok,
     %{
       kind: "Test",
       origin: "Test",
       source: "Test"
     }}
  end

  def get_fields(%{}, _, _) do
    {:ok,
     [
       %{
         from: "Test",
         to: "Test",
         type: "Test",
         format: "Test",
         order: 0
       }
     ]}
  end

  def edit_conf(_, _) do
    {:ok,
     [
       %{
         kind: "Test",
         origin: "Test",
         source: "Test"
       }
     ]}
  end

  def edit_field(_, _) do
    {:ok,
     [
       %{
         from: "Test",
         to: "Test",
         type: "Test",
         format: "Test",
         order: 0
       }
     ]}
  end

  def test(_, _) do
    {:ok, %{

    }}
  end
end
