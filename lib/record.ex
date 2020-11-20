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

  def evaluate_where_clause(record, clause) do
    Enum.reduce(clause, true, fn
      _, false ->
        false
      {header, value}, true ->
        Map.fetch(record, header) == {:ok, value}
    end)
  end

end
