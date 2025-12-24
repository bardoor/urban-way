defmodule UrbanWay.Graph do
  alias Bolt.Sips

  def query(cypher, params \\ %{}) do
    Sips.conn()
    |> Sips.query(cypher, params)
  end

  def query!(cypher, params \\ %{}) do
    Sips.conn()
    |> Sips.query!(cypher, params)
  end

  def run(%UrbanWay.Graph.Query{} = q) do
    {cypher, params} = UrbanWay.Graph.Query.to_cypher(q)
    query(cypher, params)
  end

  def run!(%UrbanWay.Graph.Query{} = q) do
    {cypher, params} = UrbanWay.Graph.Query.to_cypher(q)
    query!(cypher, params)
  end
end
