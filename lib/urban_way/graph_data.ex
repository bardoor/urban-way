defmodule UrbanWay.GraphData do
  @moduledoc "Fetches all graph data for visualization"

  alias UrbanWay.Graph

  def all do
    %{
      stops: fetch_stops(),
      locations: fetch_locations(),
      next_edges: fetch_next_edges(),
      transfer_edges: fetch_transfer_edges(),
      nearby_edges: fetch_nearby_edges()
    }
  end

  defp fetch_stops do
    "MATCH (s:Stop) RETURN s.id as id, s.name as name, s.latitude as lat, s.longitude as lon"
    |> Graph.query!()
    |> Map.get(:results, [])
    |> Enum.map(fn r -> %{id: r["id"], name: r["name"], lat: r["lat"], lon: r["lon"]} end)
  end

  defp fetch_locations do
    "MATCH (l:Location) RETURN l.id as id, l.name as name"
    |> Graph.query!()
    |> Map.get(:results, [])
    |> Enum.map(fn r -> %{id: r["id"], name: r["name"]} end)
  end

  defp fetch_next_edges do
    "MATCH (a:Stop)-[r:NEXT]->(b:Stop) RETURN a.id as from_id, b.id as to_id, r.route as route"
    |> Graph.query!()
    |> Map.get(:results, [])
    |> Enum.map(fn r -> %{from: r["from_id"], to: r["to_id"], route: r["route"]} end)
  end

  defp fetch_transfer_edges do
    "MATCH (a:Stop)-[:TRANSFER]->(b:Stop) RETURN a.id as from_id, b.id as to_id"
    |> Graph.query!()
    |> Map.get(:results, [])
    |> Enum.map(fn r -> %{from: r["from_id"], to: r["to_id"]} end)
  end

  defp fetch_nearby_edges do
    "MATCH (l:Location)-[:NEARBY]->(s:Stop) RETURN l.id as loc_id, s.id as stop_id"
    |> Graph.query!()
    |> Map.get(:results, [])
    |> Enum.map(fn r -> %{location: r["loc_id"], stop: r["stop_id"]} end)
  end
end
