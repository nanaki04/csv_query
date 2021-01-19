defmodule CsvEditor.Query.Search do

  defstruct key_term: nil,
    value_term: ""

  def terms(value_term) do
    %__MODULE__{value_term: value_term}
  end

  def terms(%__MODULE__{} = query, value_term) do
    Map.put(query, :value_term, value_term)
  end

  def terms(key_term, value_term) do
    %__MODULE__{key_term: key_term, value_term: value_term}
  end

  def terms(query, key_term, value_term) do
    Map.put(query, :key_term, key_term)
    |> Map.put(:value_term, value_term)
  end

end
