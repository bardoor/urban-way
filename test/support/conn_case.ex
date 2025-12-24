defmodule UrbanWayWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint UrbanWayWeb.Endpoint

      use UrbanWayWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import UrbanWayWeb.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
