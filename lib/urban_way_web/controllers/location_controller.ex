defmodule UrbanWayWeb.LocationController do
  use UrbanWayWeb, :controller

  alias UrbanWay.Locations

  action_fallback UrbanWayWeb.FallbackController

  def index(conn, params) do
    json(conn, %{status: :ok, locations: Locations.all(params)})
  end

  def show(conn, %{"id" => id}) do
    with {:ok, location} <- Locations.get(id) do
      json(conn, %{status: :ok, location: location})
    end
  end

  def create(conn, params) do
    with {:ok, location} <- Locations.create(params) do
      json(conn, %{status: :ok, location: location})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, location} <- Locations.update(id, params) do
      json(conn, %{status: :ok, location: location})
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- Locations.delete(id) do
      json(conn, %{status: :ok})
    end
  end
end
