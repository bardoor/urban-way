defmodule UrbanWay.Graph.Node do
  @moduledoc """
  Унифицированное преобразование Neo4j нод в map.
  """

  def to_map(%{properties: props}, fields) when is_list(fields) do
    Map.new(fields, fn field ->
      value = Map.get(props, Atom.to_string(field))
      {field, value}
    end)
  end
end
