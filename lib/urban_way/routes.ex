defmodule UrbanWay.Routes do
  alias UrbanWay.Graph
  alias UrbanWay.Graph.{Query, Result, Node}

  @query_schema %{
    filters: [{:name, :contains, :string}],
    sortable_fields: [:name]
  }

  @node_fields [:id, :name]
  @stop_fields [:id, :name, :latitude, :longitude]

  @get_stops_cypher """
  MATCH (a:Stop)-[r:NEXT{route: $route}]->(b:Stop)
  WITH collect(DISTINCT a) + collect(DISTINCT b) as all_stops
  UNWIND all_stops as stop
  RETURN DISTINCT stop
  """

  def all(params \\ %{}) do
    :Route
    |> Query.from_params("r", params, @query_schema)
    |> Graph.run!()
    |> Result.extract_list("r")
    |> Enum.map(&node_to_map/1)
  end

  def get(id) do
    "MATCH (r:Route {id: $id}) RETURN r"
    |> Graph.query!(%{id: id})
    |> Result.extract_one("r")
    |> map_node_result()
  end

  def get_stops(route_name) do
    @get_stops_cypher
    |> Graph.query!(%{route: route_name})
    |> Result.extract_list("stop")
    |> Enum.map(&Node.to_map(&1, @stop_fields))
  end

  def create(attrs) do
    "CREATE (r:Route {id: $id, name: $name}) RETURN r"
    |> Graph.query!(%{id: UUID.uuid4(), name: attrs["name"]})
    |> Result.extract_one("r")
    |> map_node_result()
    |> case do
      {:ok, _} = result -> result
      {:error, :not_found} -> {:error, :create_failed}
    end
  end

  def update(id, attrs) do
    "MATCH (r:Route {id: $id}) SET r.name = $name RETURN r"
    |> Graph.query!(%{id: id, name: attrs["name"]})
    |> Result.extract_one("r")
    |> map_node_result()
  end

  def delete(id) do
    "MATCH (r:Route {id: $id}) DETACH DELETE r RETURN count(r) as cnt"
    |> Graph.query!(%{id: id})
    |> Result.check_deleted()
  end

  defp node_to_map(node), do: Node.to_map(node, @node_fields)

  defp map_node_result({:ok, node}), do: {:ok, node_to_map(node)}
  defp map_node_result(error), do: error
end
