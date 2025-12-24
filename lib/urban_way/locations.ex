defmodule UrbanWay.Locations do
  alias UrbanWay.Graph
  alias UrbanWay.Graph.{Query, Result, Node}

  @query_schema %{
    filters: [{:name, :contains, :string}],
    sortable_fields: [:name]
  }

  @node_fields [:id, :name]

  def all(params \\ %{}) do
    :Location
    |> Query.from_params("l", params, @query_schema)
    |> Graph.run!()
    |> Result.extract_list("l")
    |> Enum.map(&node_to_map/1)
  end

  def get(id) do
    "MATCH (l:Location {id: $id}) RETURN l"
    |> Graph.query!(%{id: id})
    |> Result.extract_one("l")
    |> map_node_result()
  end

  def create(attrs) do
    "CREATE (l:Location {id: $id, name: $name}) RETURN l"
    |> Graph.query!(%{id: UUID.uuid4(), name: attrs["name"]})
    |> Result.extract_one("l")
    |> map_node_result()
    |> case do
      {:ok, _} = result -> result
      {:error, :not_found} -> {:error, :create_failed}
    end
  end

  def update(id, attrs) do
    "MATCH (l:Location {id: $id}) SET l.name = $name RETURN l"
    |> Graph.query!(%{id: id, name: attrs["name"]})
    |> Result.extract_one("l")
    |> map_node_result()
  end

  def delete(id) do
    "MATCH (l:Location {id: $id}) DETACH DELETE l RETURN count(l) as cnt"
    |> Graph.query!(%{id: id})
    |> Result.check_deleted()
  end

  defp node_to_map(node), do: Node.to_map(node, @node_fields)

  defp map_node_result({:ok, node}), do: {:ok, node_to_map(node)}
  defp map_node_result(error), do: error
end
