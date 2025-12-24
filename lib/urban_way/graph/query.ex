defmodule UrbanWay.Graph.Query do
  @moduledoc """
  Query builder для Cypher-запросов с автоматическим парсингом параметров.
  """

  defstruct [:label, :var, filters: [], order_by: nil, limit: nil, skip: nil]

  @doc """
  Создаёт запрос из сырых HTTP-параметров по схеме.

  ## Schema format
      %{
        filters: [
          {:name, :contains, :string},
          {:latitude, :gte, :float, param_key: "lat_min"}
        ],
        sortable_fields: [:name, :latitude]
      }
  """
  def from_params(label, var, params, schema) do
    label
    |> new(var)
    |> apply_filters(params, schema[:filters] || [])
    |> apply_pagination(params, schema[:sortable_fields] || [])
  end

  def new(label, var), do: %__MODULE__{label: label, var: var}

  def filter(query, _field, _op, nil), do: query

  def filter(query, field, op, value) do
    %{query | filters: [{field, op, value} | query.filters]}
  end

  def order(query, nil, _dir), do: query

  def order(query, field, dir) do
    %{query | order_by: {field, dir || :asc}}
  end

  def limit(query, nil), do: query
  def limit(query, n) when is_integer(n), do: %{query | limit: n}

  def skip(query, nil), do: query
  def skip(query, n) when is_integer(n), do: %{query | skip: n}

  def to_cypher(%__MODULE__{} = q) do
    {where_clause, params} = build_where(q.filters, q.var)

    cypher =
      "MATCH (#{q.var}:#{q.label})" <>
        where_clause <>
        " RETURN #{q.var}" <>
        build_order(q.order_by, q.var) <>
        build_skip(q.skip) <>
        build_limit(q.limit)

    {cypher, params}
  end

  # --- Private: Schema-based parsing ---

  defp apply_filters(query, params, filters) do
    Enum.reduce(filters, query, fn filter_spec, acc ->
      apply_filter(acc, params, filter_spec)
    end)
  end

  defp apply_filter(query, params, {field, op, type}) do
    apply_filter(query, params, {field, op, type, []})
  end

  defp apply_filter(query, params, {field, op, type, opts}) do
    param_key = Keyword.get(opts, :param_key, Atom.to_string(field))
    raw_value = params[param_key]
    parsed = parse_value(raw_value, type)
    filter(query, field, op, parsed)
  end

  defp apply_pagination(query, params, sortable_fields) do
    query
    |> order(parse_sort(params["sort"], sortable_fields), parse_order(params["order"]))
    |> limit(parse_int(params["limit"]))
    |> skip(parse_int(params["skip"]))
  end

  # --- Private: Value parsing ---

  defp parse_value(nil, _type), do: nil
  defp parse_value(val, :string), do: val
  defp parse_value(val, :integer), do: parse_int(val)
  defp parse_value(val, :float), do: parse_float(val)

  defp parse_int(nil), do: nil
  defp parse_int(val) when is_integer(val), do: val

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {num, _rest} -> num
      :error -> nil
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val * 1.0

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _rest} -> num
      :error -> nil
    end
  end

  defp parse_order("desc"), do: :desc
  defp parse_order("asc"), do: :asc
  defp parse_order(_), do: nil

  defp parse_sort(nil, _allowed), do: nil

  defp parse_sort(field, allowed) when is_binary(field) do
    atom = String.to_existing_atom(field)
    if atom in allowed, do: atom, else: nil
  rescue
    ArgumentError -> nil
  end

  # --- Private: Cypher building ---

  defp build_where([], _var), do: {"", %{}}

  defp build_where(filters, var) do
    {clauses, params} =
      filters
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reduce({[], %{}}, fn {{field, op, value}, idx}, {clauses, params} ->
        param_name = "p#{idx}"
        condition = "#{var}.#{field} #{op_to_cypher(op)} $#{param_name}"
        {[condition | clauses], Map.put(params, String.to_atom(param_name), value)}
      end)

    case clauses do
      [] -> {"", params}
      _ -> {" WHERE " <> Enum.join(Enum.reverse(clauses), " AND "), params}
    end
  end

  defp op_to_cypher(:eq), do: "="
  defp op_to_cypher(:contains), do: "CONTAINS"
  defp op_to_cypher(:gt), do: ">"
  defp op_to_cypher(:gte), do: ">="
  defp op_to_cypher(:lt), do: "<"
  defp op_to_cypher(:lte), do: "<="

  defp build_order(nil, _var), do: ""

  defp build_order({field, dir}, var) do
    direction = if dir == :desc, do: "DESC", else: "ASC"
    " ORDER BY #{var}.#{field} #{direction}"
  end

  defp build_skip(nil), do: ""
  defp build_skip(n), do: " SKIP #{n}"

  defp build_limit(nil), do: ""
  defp build_limit(n), do: " LIMIT #{n}"
end
