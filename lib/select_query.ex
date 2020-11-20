defmodule CsvEditor.Query.Select do

  defstruct table: "",
    where: [],
    values: [],
    distinct: false

  def value(value) do
    %__MODULE__{values: [value]}
  end

  def value(%__MODULE__{} = query, value) do
    Map.put(query, :values, [value | query.values])
  end

  def values(values) do
    Enum.reduce(values, %__MODULE__{}, fn v, acc -> value(acc, v) end)
  end

  def values(%__MODULE__{} = query, values) do
    Enum.reduce(values, query, fn v, acc -> value(acc, v) end)
  end

  def from(table) do
    %__MODULE__{table: table}
  end

  def from(%__MODULE__{} = query, table) do
    Map.put(query, :table, table)
  end

  def where(%__MODULE__{} = query, column, value) do
    Map.put(query, :where, [{column, value} | query.where])
  end

  def distinct(%__MODULE__{} = query) do
    Map.put(query, :distinct, true)
  end

end
