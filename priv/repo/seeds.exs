# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias UrbanWay.Graph

IO.puts("Очистка базы данных...")
Graph.query!("MATCH (n) DETACH DELETE n")

IO.puts("Создание остановок...")

stops = [
  %{name: "Рыночная", lat: 55.751, lon: 37.618},
  %{name: "Булковая", lat: 55.755, lon: 37.622},
  %{name: "Церковная", lat: 55.760, lon: 37.628},
  %{name: "Фортраночная", lat: 55.762, lon: 37.632},
  %{name: "Губко-бобочная", lat: 55.768, lon: 37.640},
  %{name: "Райан-Гослинговая", lat: 55.775, lon: 37.650}
]

stop_ids =
  for stop <- stops, into: %{} do
    id = UUID.uuid4()
    Graph.query!(
      "CREATE (s:Stop {id: $id, name: $name, latitude: $lat, longitude: $lon}) RETURN s",
      %{id: id, name: stop.name, lat: stop.lat, lon: stop.lon}
    )
    {stop.name, id}
  end

IO.puts("\nСоздание локаций...")

locations = [
  %{name: "Рынок", near_stop: "Рыночная"},
  %{name: "Булочная", near_stop: "Булковая"},
  %{name: "Кирха", near_stop: "Церковная"},
  %{name: "Памятник Фортрану", near_stop: "Фортраночная"},
  %{name: "Дом Губки Боба", near_stop: "Губко-бобочная"},
  %{name: "Апартаменты Райана Гослинга", near_stop: "Райан-Гослинговая"}
]

location_ids =
  for loc <- locations, into: %{} do
    id = UUID.uuid4()
    Graph.query!(
      "CREATE (l:Location {id: $id, name: $name}) RETURN l",
      %{id: id, name: loc.name}
    )
    {loc.name, id}
  end

IO.puts("\nСоздание связей NEARBY (локация рядом с остановкой)...")

for loc <- locations do
  stop_id = stop_ids[loc.near_stop]
  loc_id = location_ids[loc.name]
  Graph.query!(
    "MATCH (l:Location {id: $loc_id}), (s:Stop {id: $stop_id}) CREATE (l)-[:NEARBY]->(s)",
    %{loc_id: loc_id, stop_id: stop_id}
  )
end

IO.puts("\nСоздание маршрутов...")

routes = ["Трамвай №3", "Автобус №9"]

for route <- routes do
  id = UUID.uuid4()
  Graph.query!(
    "CREATE (r:Route {id: $id, name: $name}) RETURN r",
    %{id: id, name: route}
  )
end

IO.puts("\nСоздание связей NEXT (следующая остановка)...")

tram_stops = ["Рыночная", "Булковая", "Церковная"]
tram_route = "Трамвай №3"

for [from, to] <- Enum.chunk_every(tram_stops, 2, 1, :discard) do
  Graph.query!(
    "MATCH (a:Stop {id: $from_id}), (b:Stop {id: $to_id}) CREATE (a)-[:NEXT {route: $route}]->(b)",
    %{from_id: stop_ids[from], to_id: stop_ids[to], route: tram_route}
  )
end

bus_stops = ["Фортраночная", "Губко-бобочная", "Райан-Гослинговая"]
bus_route = "Автобус №9"

for [from, to] <- Enum.chunk_every(bus_stops, 2, 1, :discard) do
  Graph.query!(
    "MATCH (a:Stop {id: $from_id}), (b:Stop {id: $to_id}) CREATE (a)-[:NEXT {route: $route}]->(b)",
    %{from_id: stop_ids[from], to_id: stop_ids[to], route: bus_route}
  )
end

IO.puts("\nСоздание пересадки TRANSFER...")


Graph.query!(
  "MATCH (a:Stop {id: $from_id}), (b:Stop {id: $to_id}) CREATE (a)-[:TRANSFER]->(b)",
  %{from_id: stop_ids["Церковная"], to_id: stop_ids["Фортраночная"]}
)
