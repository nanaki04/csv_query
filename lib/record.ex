defmodule CsvEditor.Record do

  def values(record) do
    Enum.map(record, fn {_, value} -> value end)
  end

  def serialize(record, headers) do
    headers
    |> Enum.map(fn header -> Map.fetch(record, header) end)
    |> Enum.map(fn
      {:ok, value} -> value
      _ -> ""
    end)
    |> Enum.map(fn record -> "\"#{record}\"" end)
    |> Enum.join(",")
  end

  def evaluate_where_clause(record, clause, idx) do
    Enum.reduce(clause, true, fn
      _, false ->
        false
      {"index", index}, true ->
        "#{idx}" == index
      {header, value}, true ->
        Map.fetch(record, header) == {:ok, value}
    end)
  end

  def evaluate_value_term(record, term) do
    {:ok, pattern} = Regex.compile(term)
    Map.values(record)
    |> Enum.any?(fn value -> Regex.match?(pattern, value) end)
  end

  def evaluate_key_value_terms(record, key_term, value_term) do
    {:ok, key_pattern} = Regex.compile(key_term)

    Map.keys(record)
    |> Enum.filter(fn key -> Regex.match?(key_pattern, key) end)
    |> (fn keys -> Map.take(record, keys) end).()
    |> evaluate_value_term(value_term)
  end

end
