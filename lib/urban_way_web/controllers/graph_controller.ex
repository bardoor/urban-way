defmodule UrbanWayWeb.GraphController do
  use UrbanWayWeb, :controller

  alias UrbanWay.GraphData

  def index(conn, _params) do
    json(conn, %{status: :ok, graph: GraphData.all()})
  end
end
