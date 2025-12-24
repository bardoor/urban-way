defmodule UrbanWayWeb.RelationshipController do
  use UrbanWayWeb, :controller

  alias UrbanWay.Relationships

  action_fallback UrbanWayWeb.FallbackController

  # --- NEXT ---

  def index_next(conn, params) do
    json(conn, %{status: :ok, next: Relationships.all_next(route: params["route"])})
  end

  def create_next(conn, %{"from_id" => from_id, "to_id" => to_id, "route" => route}) do
    with {:ok, rel} <- Relationships.create_next(from_id, to_id, route) do
      json(conn, %{relationship: rel})
    end
  end

  def delete_next(conn, %{"from_id" => from_id, "to_id" => to_id, "route" => route}) do
    with :ok <- Relationships.delete_next(from_id, to_id, route) do
      json(conn, %{status: :ok})
    end
  end

  # --- TRANSFERS ---

  def index_transfers(conn, _params) do
    json(conn, %{transfers: Relationships.all_transfers()})
  end

  def create_transfer(conn, %{"from_id" => from_id, "to_id" => to_id}) do
    with {:ok, rel} <- Relationships.create_transfer(from_id, to_id) do
      json(conn, %{status: :ok, relationship: rel})
    end
  end

  def delete_transfer(conn, %{"from_id" => from_id, "to_id" => to_id}) do
    with :ok <- Relationships.delete_transfer(from_id, to_id) do
      json(conn, %{status: :ok})
    end
  end

  # --- NEARBY ---

  def index_nearby(conn, params) do
    nearby_rels = Relationships.all_nearby(location_id: params["location_id"])
    json(conn, %{relationships: nearby_rels})
  end

  def create_nearby(conn, %{"location_id" => location_id, "stop_id" => stop_id}) do
    with {:ok, rel} <- Relationships.create_nearby(location_id, stop_id) do
      json(conn, %{status: :ok, relationship: rel})
    end
  end

  def delete_nearby(conn, %{"location_id" => location_id, "stop_id" => stop_id}) do
    with :ok <- Relationships.delete_nearby(location_id, stop_id) do
      json(conn, %{status: :ok})
    end
  end
end
