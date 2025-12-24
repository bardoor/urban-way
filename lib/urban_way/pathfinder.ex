defmodule UrbanWay.Pathfinder do
  @moduledoc false

  alias UrbanWay.Graph

  def find_path(from_location_id, to_location_id) do
    cypher = """
    MATCH (from_loc:Location {id: $from_id})-[:NEARBY]->(start:Stop),
          (to_loc:Location {id: $to_id})-[:NEARBY]->(end:Stop),
          path = shortestPath((start)-[:NEXT|TRANSFER*]-(end))
    RETURN from_loc, to_loc, start, end, path,
           [rel in relationships(path) | type(rel)] as rel_types,
           [rel in relationships(path) | rel.route] as routes,
           [node in nodes(path) | node] as stops
    ORDER BY length(path)
    LIMIT 1
    """

    case Graph.query!(cypher, %{from_id: from_location_id, to_id: to_location_id}).results do
      [result] ->
        {:ok, build_path_response(result)}

      [] ->
        check_why_no_path(from_location_id, to_location_id)
    end
  end

  defp check_why_no_path(from_id, to_id) do
    cond do
      !location_exists?(from_id) -> {:error, :location_not_found}
      !location_exists?(to_id) -> {:error, :location_not_found}
      !has_nearby_stops?(from_id) -> {:error, :no_nearby_stops}
      !has_nearby_stops?(to_id) -> {:error, :no_nearby_stops}
      true -> {:error, :no_path_found}
    end
  end

  defp location_exists?(id) do
    cypher = "MATCH (l:Location {id: $id}) RETURN count(l) as cnt"
    [%{"cnt" => cnt}] = Graph.query!(cypher, %{id: id}).results
    cnt > 0
  end

  defp has_nearby_stops?(location_id) do
    cypher = "MATCH (:Location {id: $id})-[:NEARBY]->(:Stop) RETURN count(*) as cnt"
    [%{"cnt" => cnt}] = Graph.query!(cypher, %{id: location_id}).results
    cnt > 0
  end

  defp build_path_response(result) do
    from_loc = node_to_map(result["from_loc"])
    to_loc = node_to_map(result["to_loc"])
    stops = Enum.map(result["stops"], &node_to_map/1)
    rel_types = result["rel_types"]
    routes = result["routes"]

    steps = build_steps(stops, rel_types, routes, from_loc, to_loc)

    %{
      from_location: from_loc,
      to_location: to_loc,
      steps: steps
    }
  end

  defp build_steps(stops, rel_types, routes, _from_loc, to_loc) do
    first_stop = List.first(stops)

    edges =
      stops
      |> Enum.zip(Enum.drop(stops, 1))
      |> Enum.zip(rel_types)
      |> Enum.zip(routes)
      |> Enum.map(fn {{{from, to}, type}, route} ->
        %{from: from, to: to, type: type, route: route}
      end)

    walk_to = [%{type: "walk_to_stop", stop: first_stop}]
    ride_steps = edges |> group_edges() |> Enum.flat_map(&build_segment/1)
    walk_from = [%{type: "walk_to_location", location: to_loc}]

    walk_to ++ ride_steps ++ walk_from
  end

  defp group_edges(edges) do
    Enum.chunk_by(edges, fn e -> {e.type, e.route} end)
  end

  defp build_segment([%{type: "TRANSFER"} = edge | _rest] = _chunk) do
    [%{type: "transfer", from_stop: edge.from.name, to_stop: edge.to.name}]
  end

  defp build_segment(chunk) do
    %{route: route} = hd(chunk)
    stop_names = [hd(chunk).from.name | Enum.map(chunk, & &1.to.name)]
    [%{type: "ride", route: route, stops: stop_names, count: length(stop_names)}]
  end

  defp node_to_map(node) do
    %{
      id: node.properties["id"],
      name: node.properties["name"]
    }
  end
end
