defmodule UrbanWayWeb.PageController do
  use UrbanWayWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Application.app_dir(:urban_way, "priv/static/index.html"))
  end
end
