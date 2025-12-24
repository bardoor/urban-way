defmodule UrbanWay.Relationships do
  alias UrbanWay.Graph
  alias UrbanWay.Graph.Result

  # --- NEXT relationships ---

  @all_next_base "MATCH (from:Stop)-[n:NEXT]->(to:Stop) RETURN from, n, to"
  @all_next_filtered "MATCH (from:Stop)-[n:NEXT {route: $route}]->(to:Stop) RETURN from, n, to"

  @create_next_cypher """
  MATCH (from:Stop {id: $from_id}), (to:Stop {id: $to_id})
  CREATE (from)-[n:NEXT {route: $route}]->(to)
  RETURN from, n, to
  """

  @delete_next_cypher """
  MATCH (from:Stop {id: $from_id})-[n:NEXT {route: $route}]->(to:Stop {id: $to_id})
  DELETE n
  RETURN count(n) as cnt
  """

  def all_next(opts \\ []) do
    {cypher, params} = optional_filter(opts[:route], @all_next_base, @all_next_filtered, :route)

    cypher
    |> Graph.query!(params)
    |> Map.get(:results)
    |> Enum.map(&next_rel_to_map/1)
  end

  def create_next(from_id, to_id, route) do
    @create_next_cypher
    |> Graph.query!(%{from_id: from_id, to_id: to_id, route: route})
    |> extract_created(&next_rel_created_to_map/1, :stops_not_found)
  end

  def delete_next(from_id, to_id, route) do
    @delete_next_cypher
    |> Graph.query!(%{from_id: from_id, to_id: to_id, route: route})
    |> Result.check_deleted()
  end

  # --- TRANSFER relationships ---

  @all_transfers_cypher "MATCH (from:Stop)-[t:TRANSFER]->(to:Stop) RETURN from, to"

  @create_transfer_cypher """
  MATCH (from:Stop {id: $from_id}), (to:Stop {id: $to_id})
  CREATE (from)-[t:TRANSFER]->(to)
  RETURN from, to
  """

  @delete_transfer_cypher """
  MATCH (from:Stop {id: $from_id})-[t:TRANSFER]->(to:Stop {id: $to_id})
  DELETE t
  RETURN count(t) as cnt
  """

  def all_transfers do
    @all_transfers_cypher
    |> Graph.query!(%{})
    |> Map.get(:results)
    |> Enum.map(&transfer_to_map/1)
  end

  def create_transfer(from_id, to_id) do
    @create_transfer_cypher
    |> Graph.query!(%{from_id: from_id, to_id: to_id})
    |> extract_created(&transfer_created_to_map/1, :stops_not_found)
  end

  def delete_transfer(from_id, to_id) do
    @delete_transfer_cypher
    |> Graph.query!(%{from_id: from_id, to_id: to_id})
    |> Result.check_deleted()
  end

  # --- NEARBY relationships ---

  @all_nearby_base "MATCH (l:Location)-[n:NEARBY]->(s:Stop) RETURN l, s"
  @all_nearby_filtered "MATCH (l:Location {id: $location_id})-[n:NEARBY]->(s:Stop) RETURN l, s"

  @create_nearby_cypher """
  MATCH (l:Location {id: $location_id}), (s:Stop {id: $stop_id})
  CREATE (l)-[n:NEARBY]->(s)
  RETURN l, s
  """

  @delete_nearby_cypher """
  MATCH (l:Location {id: $location_id})-[n:NEARBY]->(s:Stop {id: $stop_id})
  DELETE n
  RETURN count(n) as cnt
  """

  def all_nearby(opts \\ []) do
    {cypher, params} =
      optional_filter(opts[:location_id], @all_nearby_base, @all_nearby_filtered, :location_id)

    cypher
    |> Graph.query!(params)
    |> Map.get(:results)
    |> Enum.map(&nearby_to_map/1)
  end

  def create_nearby(location_id, stop_id) do
    @create_nearby_cypher
    |> Graph.query!(%{location_id: location_id, stop_id: stop_id})
    |> extract_created(&nearby_created_to_map/1, :nodes_not_found)
  end

  def delete_nearby(location_id, stop_id) do
    @delete_nearby_cypher
    |> Graph.query!(%{location_id: location_id, stop_id: stop_id})
    |> Result.check_deleted()
  end

  # --- Private helpers ---

  defp optional_filter(nil, base_cypher, _filtered_cypher, _key), do: {base_cypher, %{}}

  defp optional_filter(value, _base_cypher, filtered_cypher, key),
    do: {filtered_cypher, %{key => value}}

  defp extract_created(%{results: [row]}, mapper, _error), do: {:ok, mapper.(row)}
  defp extract_created(_results, _mapper, error), do: {:error, error}

  defp next_rel_to_map(%{"from" => from, "n" => rel, "to" => to}) do
    %{
      from_id: from.properties["id"],
      from_name: from.properties["name"],
      to_id: to.properties["id"],
      to_name: to.properties["name"],
      route: rel.properties["route"]
    }
  end

  defp next_rel_created_to_map(%{"from" => from, "n" => rel, "to" => to}) do
    %{from_id: from.properties["id"], to_id: to.properties["id"], route: rel.properties["route"]}
  end

  defp transfer_to_map(%{"from" => from, "to" => to}) do
    %{
      from_id: from.properties["id"],
      from_name: from.properties["name"],
      to_id: to.properties["id"],
      to_name: to.properties["name"]
    }
  end

  defp transfer_created_to_map(%{"from" => from, "to" => to}) do
    %{from_id: from.properties["id"], to_id: to.properties["id"]}
  end

  defp nearby_to_map(%{"l" => loc, "s" => stop}) do
    %{
      location_id: loc.properties["id"],
      location_name: loc.properties["name"],
      stop_id: stop.properties["id"],
      stop_name: stop.properties["name"]
    }
  end

  defp nearby_created_to_map(%{"l" => loc, "s" => stop}) do
    %{location_id: loc.properties["id"], stop_id: stop.properties["id"]}
  end
end
