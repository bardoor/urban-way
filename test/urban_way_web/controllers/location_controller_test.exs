defmodule UrbanWayWeb.LocationControllerTest do
  use UrbanWayWeb.ConnCase

  setup do
    UrbanWay.Graph.query!("MATCH (n:Location) DETACH DELETE n")
    :ok
  end

  describe "index" do
    test "returns empty list when no locations", %{conn: conn} do
      conn = get(conn, ~p"/api/locations")
      assert %{"status" => "ok", "locations" => []} = json_response(conn, 200)
    end

    test "returns all locations", %{conn: conn} do
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Рынок"})
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Театр"})

      conn = get(conn, ~p"/api/locations")
      assert %{"status" => "ok", "locations" => [_, _]} = json_response(conn, 200)
    end

    test "filters by name", %{conn: conn} do
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Рынок"})
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Театр"})

      conn = get(conn, ~p"/api/locations?name=Рынок")
      assert %{"status" => "ok", "locations" => [%{"name" => "Рынок"}]} = json_response(conn, 200)
    end

    test "sorts by name", %{conn: conn} do
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Яблоко"})
      {:ok, _} = UrbanWay.Locations.create(%{"name" => "Арбуз"})

      conn = get(conn, ~p"/api/locations?sort=name&order=asc")
      assert %{"status" => "ok", "locations" => [%{"name" => "Арбуз"}, %{"name" => "Яблоко"}]} = json_response(conn, 200)

      conn = get(conn, ~p"/api/locations?sort=name&order=desc")
      assert %{"status" => "ok", "locations" => [%{"name" => "Яблоко"}, %{"name" => "Арбуз"}]} = json_response(conn, 200)
    end
  end

  describe "show" do
    test "returns location by id", %{conn: conn} do
      {:ok, %{id: id}} = UrbanWay.Locations.create(%{"name" => "Рынок"})

      conn = get(conn, ~p"/api/locations/#{id}")
      assert %{"status" => "ok", "location" => %{"id" => ^id, "name" => "Рынок"}} = json_response(conn, 200)
    end

    test "returns 404 for non-existent location", %{conn: conn} do
      conn = get(conn, ~p"/api/locations/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end

  describe "create" do
    test "creates location with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/locations", %{"name" => "Новая локация"})

      assert %{"status" => "ok", "location" => %{"id" => _, "name" => "Новая локация"}} = json_response(conn, 200)
    end
  end

  describe "delete" do
    test "deletes existing location", %{conn: conn} do
      {:ok, %{id: id}} = UrbanWay.Locations.create(%{"name" => "Удаляемая"})

      conn = delete(conn, ~p"/api/locations/#{id}")
      assert %{"status" => "ok"} = json_response(conn, 200)

      assert {:error, :not_found} = UrbanWay.Locations.get(id)
    end

    test "returns 404 for non-existent location", %{conn: conn} do
      conn = delete(conn, ~p"/api/locations/non-existent-id")
      assert %{"error" => "Not found"} = json_response(conn, 404)
    end
  end
end
