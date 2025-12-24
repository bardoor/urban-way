defmodule UrbanWayWeb.RelationshipControllerTest do
  use UrbanWayWeb.ConnCase

  setup do
    UrbanWay.Graph.query!("MATCH (n) DETACH DELETE n")

    {:ok, s1} =
      UrbanWay.Stops.create(%{"name" => "S1", "latitude" => 55.70, "longitude" => 37.60})

    {:ok, s2} =
      UrbanWay.Stops.create(%{"name" => "S2", "latitude" => 55.75, "longitude" => 37.65})

    {:ok, s3} =
      UrbanWay.Stops.create(%{"name" => "S3", "latitude" => 55.80, "longitude" => 37.70})

    {:ok, loc} = UrbanWay.Locations.create(%{"name" => "Рынок"})

    %{s1: s1, s2: s2, s3: s3, loc: loc}
  end

  describe "NEXT relationships" do
    test "index_next returns empty list when no relationships", %{conn: conn} do
      conn = get(conn, ~p"/api/relationships/next")
      assert %{"status" => "ok", "next" => []} = json_response(conn, 200)
    end

    test "create_next creates relationship", %{conn: conn, s1: s1, s2: s2} do
      conn =
        post(conn, ~p"/api/relationships/next", %{
          "from_id" => s1.id,
          "to_id" => s2.id,
          "route" => "Bus 5"
        })

      assert %{"relationship" => %{"from_id" => _, "to_id" => _, "route" => "Bus 5"}} =
               json_response(conn, 200)
    end

    test "index_next returns created relationships", %{conn: conn, s1: s1, s2: s2} do
      {:ok, _} = UrbanWay.Relationships.create_next(s1.id, s2.id, "Bus 5")

      conn = get(conn, ~p"/api/relationships/next")
      assert %{"status" => "ok", "next" => [%{"route" => "Bus 5"}]} = json_response(conn, 200)
    end

    test "index_next filters by route", %{conn: conn, s1: s1, s2: s2, s3: s3} do
      {:ok, _} = UrbanWay.Relationships.create_next(s1.id, s2.id, "Bus 5")
      {:ok, _} = UrbanWay.Relationships.create_next(s2.id, s3.id, "Tram 2")

      conn = get(conn, ~p"/api/relationships/next?route=Bus 5")
      assert %{"status" => "ok", "next" => [%{"route" => "Bus 5"}]} = json_response(conn, 200)
    end

    test "delete_next removes relationship", %{conn: conn, s1: s1, s2: s2} do
      {:ok, _} = UrbanWay.Relationships.create_next(s1.id, s2.id, "Bus 5")

      conn =
        delete(conn, ~p"/api/relationships/next", %{
          "from_id" => s1.id,
          "to_id" => s2.id,
          "route" => "Bus 5"
        })

      assert %{"status" => "ok"} = json_response(conn, 200)

      conn = get(conn, ~p"/api/relationships/next")
      assert %{"status" => "ok", "next" => []} = json_response(conn, 200)
    end
  end

  describe "TRANSFER relationships" do
    test "index_transfers returns empty list when no transfers", %{conn: conn} do
      conn = get(conn, ~p"/api/relationships/transfers")
      assert %{"transfers" => []} = json_response(conn, 200)
    end

    test "create_transfer creates relationship", %{conn: conn, s1: s1, s2: s2} do
      conn =
        post(conn, ~p"/api/relationships/transfers", %{
          "from_id" => s1.id,
          "to_id" => s2.id
        })

      assert %{"status" => "ok", "relationship" => %{"from_id" => _, "to_id" => _}} = json_response(conn, 200)
    end

    test "index_transfers returns created transfers", %{conn: conn, s1: s1, s2: s2} do
      {:ok, _} = UrbanWay.Relationships.create_transfer(s1.id, s2.id)

      conn = get(conn, ~p"/api/relationships/transfers")
      assert %{"transfers" => [%{"from_name" => "S1", "to_name" => "S2"}]} = json_response(conn, 200)
    end

    test "delete_transfer removes relationship", %{conn: conn, s1: s1, s2: s2} do
      {:ok, _} = UrbanWay.Relationships.create_transfer(s1.id, s2.id)

      conn =
        delete(conn, ~p"/api/relationships/transfers", %{
          "from_id" => s1.id,
          "to_id" => s2.id
        })

      assert %{"status" => "ok"} = json_response(conn, 200)

      conn = get(conn, ~p"/api/relationships/transfers")
      assert %{"transfers" => []} = json_response(conn, 200)
    end
  end

  describe "NEARBY relationships" do
    test "index_nearby returns empty list when no nearby", %{conn: conn} do
      conn = get(conn, ~p"/api/relationships/nearby")
      assert %{"relationships" => []} = json_response(conn, 200)
    end

    test "create_nearby creates relationship", %{conn: conn, loc: loc, s1: s1} do
      conn =
        post(conn, ~p"/api/relationships/nearby", %{
          "location_id" => loc.id,
          "stop_id" => s1.id
        })

      assert %{"status" => "ok", "relationship" => %{"location_id" => _, "stop_id" => _}} = json_response(conn, 200)
    end

    test "index_nearby returns created nearby", %{conn: conn, loc: loc, s1: s1} do
      {:ok, _} = UrbanWay.Relationships.create_nearby(loc.id, s1.id)

      conn = get(conn, ~p"/api/relationships/nearby")

      assert %{"relationships" => [%{"location_name" => "Рынок", "stop_name" => "S1"}]} =
               json_response(conn, 200)
    end

    test "index_nearby filters by location_id", %{conn: conn, loc: loc, s1: s1, s2: s2} do
      {:ok, loc2} = UrbanWay.Locations.create(%{"name" => "Театр"})
      {:ok, _} = UrbanWay.Relationships.create_nearby(loc.id, s1.id)
      {:ok, _} = UrbanWay.Relationships.create_nearby(loc2.id, s2.id)

      conn = get(conn, ~p"/api/relationships/nearby?location_id=#{loc.id}")
      assert %{"relationships" => [%{"location_name" => "Рынок"}]} = json_response(conn, 200)
    end

    test "delete_nearby removes relationship", %{conn: conn, loc: loc, s1: s1} do
      {:ok, _} = UrbanWay.Relationships.create_nearby(loc.id, s1.id)

      conn =
        delete(conn, ~p"/api/relationships/nearby", %{
          "location_id" => loc.id,
          "stop_id" => s1.id
        })

      assert %{"status" => "ok"} = json_response(conn, 200)

      conn = get(conn, ~p"/api/relationships/nearby")
      assert %{"relationships" => []} = json_response(conn, 200)
    end
  end
end
