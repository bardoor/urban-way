defmodule UrbanWayWeb.PathfinderController do
  use UrbanWayWeb, :controller

  alias UrbanWay.Pathfinder

  def find(conn, %{"from_location" => from_id, "to_location" => to_id}) do
    case Pathfinder.find_path(from_id, to_id) do
      {:ok, path} ->
        json(conn, %{status: :ok, path: path})

      {:error, :location_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Location not found"})

      {:error, :no_nearby_stops} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "No nearby stops for location"})

      {:error, :no_path_found} ->
        conn |> put_status(:ok) |> json(%{error: "No path found between locations"})
    end
  end

  def find(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing from_location or to_location parameter"})
  end
end
