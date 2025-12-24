defmodule UrbanWayWeb.FallbackController do
  use UrbanWayWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Not found"})
  end

  def call(conn, {:error, :create_failed}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Create failed"})
  end

  def call(conn, {:error, :stops_not_found}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Stops not found"})
  end

  def call(conn, {:error, :nodes_not_found}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Nodes not found"})
  end

  def call(conn, {:error, reason}) when is_atom(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: Atom.to_string(reason)})
  end
end
