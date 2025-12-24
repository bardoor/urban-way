defmodule UrbanWay.Graph.Result do
  @moduledoc """
  Утилиты для извлечения данных из результатов Cypher-запросов.
  """

  def extract_one(%{results: [row]}, var) do
    with :error <- Map.fetch(row, var), do: {:error, :not_found}
  end

  def extract_one(_results, _var), do: {:error, :not_found}

  def extract_list(%{results: rows}, var) do
    for row <- rows,
        value = row[var],
        value != nil,
        do: value
  end

  def check_deleted(%{results: [result]}, key \\ "cnt") do
    case result do
      %{^key => cnt} when cnt > 0 -> :ok
      _ -> {:error, :not_found}
    end
  end
end
