defmodule UrbanWayWeb.RouteControllerTest do
  use UrbanWayWeb.ConnCase

  setup do
    UrbanWay.Graph.query!("MATCH (n) DETACH DELETE n")
    :ok
  end

  describe "index" do
    test "returns empty list when no routes", %{conn: conn} do
      conn = get(conn, ~p"/api/routes")
      assert %{"status" => "ok", "routes" => []} = json_response(conn, 200)
    end

    test "returns all routes", %{conn: conn} do
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Bus 5"})
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Tram 2"})

      conn = get(conn, ~p"/api/routes")
      assert %{"status" => "ok", "routes" => [_, _]} = json_response(conn, 200)
    end

    test "filters by name", %{conn: conn} do
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Bus 5"})
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Tram 2"})

      conn = get(conn, ~p"/api/routes?name=Bus")
      assert %{"status" => "ok", "routes" => [%{"name" => "Bus 5"}]} = json_response(conn, 200)
    end

    test "sorts by name", %{conn: conn} do
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Tram 2"})
      {:ok, _} = UrbanWay.Routes.create(%{"name" => "Bus 5"})

      conn = get(conn, ~p"/api/routes?sort=name&order=asc")
      assert %{"status" => "ok", "routes" => [%{"name" => "Bus 5"}, %{"name" => "Tram 2"}]} = json_response(conn, 200)
    end
  end

  describe "show" do
    test "returns route by id", %{conn: conn} do
      {:ok, %{id: id}} = UrbanWay.Routes.create(%{"name" => "Bus 5"})

      conn = get(conn, ~p"/api/routes/#{id}")
      assert %{"status" => "ok", "routes" => %{"id" => ^id, "name" => "Bus 5"}} = json_response(conn, 200)
    end

    test "returns 404 for non-existent route", %{conn: conn} do
      conn = get(conn, ~p"/api/routes/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end

  describe "create" do
    test "creates route with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/routes", %{"name" => "Bus 10"})

      assert %{"route" => %{"id" => _, "name" => "Bus 10"}} = json_response(conn, 200)
    end
  end

  describe "delete" do
    test "deletes existing route", %{conn: conn} do
      {:ok, %{id: id}} = UrbanWay.Routes.create(%{"name" => "Удаляемый"})

      conn = delete(conn, ~p"/api/routes/#{id}")
      assert %{"status" => "ok"} = json_response(conn, 200)

      assert {:error, :not_found} = UrbanWay.Routes.get(id)
    end

    test "returns 404 for non-existent route", %{conn: conn} do
      conn = delete(conn, ~p"/api/routes/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end

  describe "stops" do
    test "returns stops for a route", %{conn: conn} do
      {:ok, %{id: s1_id}} =
        UrbanWay.Stops.create(%{"name" => "S1", "latitude" => 55.70, "longitude" => 37.60})

      {:ok, %{id: s2_id}} =
        UrbanWay.Stops.create(%{"name" => "S2", "latitude" => 55.75, "longitude" => 37.65})

      {:ok, _} = UrbanWay.Relationships.create_next(s1_id, s2_id, "Bus 5")

      conn = get(conn, ~p"/api/routes/Bus 5/stops")
      assert %{"stops" => stops} = json_response(conn, 200)
      assert length(stops) >= 1
    end
  end
end
