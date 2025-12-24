defmodule UrbanWayWeb.StopControllerTest do
  use UrbanWayWeb.ConnCase

  setup do
    UrbanWay.Graph.query!("MATCH (n:Stop) DETACH DELETE n")
    :ok
  end

  describe "index" do
    test "returns empty list when no stops", %{conn: conn} do
      conn = get(conn, ~p"/api/stops")
      assert %{"status" => "ok", "stops" => []} = json_response(conn, 200)
    end

    test "returns all stops", %{conn: conn} do
      {:ok, _} =
        UrbanWay.Stops.create(%{
          "name" => "Центральная",
          "latitude" => 55.75,
          "longitude" => 37.61
        })

      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Северная", "latitude" => 55.80, "longitude" => 37.50})

      conn = get(conn, ~p"/api/stops")
      assert %{"status" => "ok", "stops" => [_, _]} = json_response(conn, 200)
    end

    test "filters by name", %{conn: conn} do
      {:ok, _} =
        UrbanWay.Stops.create(%{
          "name" => "Центральная",
          "latitude" => 55.75,
          "longitude" => 37.61
        })

      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Северная", "latitude" => 55.80, "longitude" => 37.50})

      conn = get(conn, ~p"/api/stops?name=Центр")
      assert %{"status" => "ok", "stops" => [%{"name" => "Центральная"}]} = json_response(conn, 200)
    end

    test "filters by latitude range", %{conn: conn} do
      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Южная", "latitude" => 55.70, "longitude" => 37.61})

      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Северная", "latitude" => 55.90, "longitude" => 37.50})

      conn = get(conn, ~p"/api/stops?lat_min=55.85&lat_max=56.0")
      assert %{"status" => "ok", "stops" => [%{"name" => "Северная"}]} = json_response(conn, 200)
    end

    test "filters by longitude range", %{conn: conn} do
      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Западная", "latitude" => 55.75, "longitude" => 37.40})

      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Восточная", "latitude" => 55.75, "longitude" => 37.70})

      conn = get(conn, ~p"/api/stops?lon_min=37.60&lon_max=37.80")
      assert %{"status" => "ok", "stops" => [%{"name" => "Восточная"}]} = json_response(conn, 200)
    end

    test "sorts by latitude", %{conn: conn} do
      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Южная", "latitude" => 55.70, "longitude" => 37.61})

      {:ok, _} =
        UrbanWay.Stops.create(%{"name" => "Северная", "latitude" => 55.90, "longitude" => 37.50})

      conn = get(conn, ~p"/api/stops?sort=latitude&order=asc")

      assert %{"status" => "ok", "stops" => [%{"name" => "Южная"}, %{"name" => "Северная"}]} =
               json_response(conn, 200)

      conn = get(conn, ~p"/api/stops?sort=latitude&order=desc")

      assert %{"status" => "ok", "stops" => [%{"name" => "Северная"}, %{"name" => "Южная"}]} =
               json_response(conn, 200)
    end
  end

  describe "show" do
    test "returns stop by id", %{conn: conn} do
      {:ok, %{id: id}} =
        UrbanWay.Stops.create(%{
          "name" => "Центральная",
          "latitude" => 55.75,
          "longitude" => 37.61
        })

      conn = get(conn, ~p"/api/stops/#{id}")
      assert %{"status" => "ok", "stop" => %{"id" => ^id, "name" => "Центральная"}} = json_response(conn, 200)
    end

    test "returns 404 for non-existent stop", %{conn: conn} do
      conn = get(conn, ~p"/api/stops/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end

  describe "create" do
    test "creates stop with valid data", %{conn: conn} do
      conn =
        post(conn, ~p"/api/stops", %{"name" => "Новая", "latitude" => 55.75, "longitude" => 37.61})

      assert %{
               "status" => "ok",
               "stop" => %{
                 "id" => _,
                 "name" => "Новая",
                 "latitude" => 55.75,
                 "longitude" => 37.61
               }
             } = json_response(conn, 200)
    end
  end

  describe "delete" do
    test "deletes existing stop", %{conn: conn} do
      {:ok, %{id: id}} =
        UrbanWay.Stops.create(%{"name" => "Удаляемая", "latitude" => 55.75, "longitude" => 37.61})

      conn = delete(conn, ~p"/api/stops/#{id}")
      assert %{"status" => "ok"} = json_response(conn, 200)

      assert {:error, :not_found} = UrbanWay.Stops.get(id)
    end

    test "returns 404 for non-existent stop", %{conn: conn} do
      conn = delete(conn, ~p"/api/stops/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end
end
