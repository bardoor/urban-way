defmodule UrbanWayWeb.StopController do
  use UrbanWayWeb, :controller

  alias UrbanWay.Stops

  action_fallback UrbanWayWeb.FallbackController

  def index(conn, params) do
    json(conn, %{status: :ok, stops: Stops.all(params)})
  end

  def show(conn, %{"id" => id}) do
    with {:ok, stop} <- Stops.get(id) do
      json(conn, %{status: :ok, stop: stop})
    end
  end

  def create(conn, params) do
    with {:ok, stop} <- Stops.create(params) do
      json(conn, %{status: :ok, stop: stop})
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- Stops.delete(id) do
      json(conn, %{status: :ok})
    end
  end
end
