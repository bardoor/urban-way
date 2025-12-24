defmodule UrbanWay.Stops do
  alias UrbanWay.Graph
  alias UrbanWay.Graph.{Query, Result, Node}

  @query_schema %{
    filters: [
      {:name, :contains, :string},
      {:latitude, :gte, :float, param_key: "lat_min"},
      {:latitude, :lte, :float, param_key: "lat_max"},
      {:longitude, :gte, :float, param_key: "lon_min"},
      {:longitude, :lte, :float, param_key: "lon_max"}
    ],
    sortable_fields: [:name, :latitude, :longitude]
  }

  @node_fields [:id, :name, :latitude, :longitude]

  def all(params \\ %{}) do
    :Stop
    |> Query.from_params("s", params, @query_schema)
    |> Graph.run!()
    |> Result.extract_list("s")
    |> Enum.map(&node_to_map/1)
  end

  def get(id) do
    "MATCH (s:Stop {id: $id}) RETURN s"
    |> Graph.query!(%{id: id})
    |> Result.extract_one("s")
    |> map_node_result()
  end

  def create(attrs) do
    "CREATE (s:Stop {id: $id, name: $name, latitude: $latitude, longitude: $longitude}) RETURN s"
    |> Graph.query!(
      %{id: UUID.uuid4(), name: attrs["name"], latitude: attrs["latitude"], longitude: attrs["longitude"]}
    )
    |> Result.extract_one("s")
    |> map_node_result()
    |> case do
      {:ok, _} = result -> result
      {:error, :not_found} -> {:error, :create_failed}
    end
  end

  def update(id, attrs) do
    "MATCH (s:Stop {id: $id}) SET s.name = $name, s.latitude = $lat, s.longitude = $lon RETURN s"
    |> Graph.query!(%{id: id, name: attrs["name"], lat: attrs["latitude"], lon: attrs["longitude"]})
    |> Result.extract_one("s")
    |> map_node_result()
  end

  def delete(id) do
    "MATCH (s:Stop {id: $id}) DETACH DELETE s RETURN count(s) as cnt"
    |> Graph.query!(%{id: id})
    |> Result.check_deleted()
  end

  defp node_to_map(node), do: Node.to_map(node, @node_fields)

  defp map_node_result({:ok, node}), do: {:ok, node_to_map(node)}
  defp map_node_result(error), do: error
end
