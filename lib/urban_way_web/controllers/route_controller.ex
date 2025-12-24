defmodule UrbanWayWeb.RouteController do
  use UrbanWayWeb, :controller

  alias UrbanWay.Routes

  action_fallback UrbanWayWeb.FallbackController

  def index(conn, params) do
    json(conn, %{status: :ok, routes: Routes.all(params)})
  end

  def show(conn, %{"id" => id}) do
    with {:ok, route} <- Routes.get(id) do
      json(conn, %{status: :ok, routes: route})
    end
  end

  def stops(conn, %{"name" => name}) do
    json(conn, %{stops: Routes.get_stops(name)})
  end

  def create(conn, params) do
    with {:ok, route} <- Routes.create(params) do
      json(conn, %{route: route})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, route} <- Routes.update(id, params) do
      json(conn, %{status: :ok, route: route})
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- Routes.delete(id) do
      json(conn, %{status: :ok})
    end
  end
end
