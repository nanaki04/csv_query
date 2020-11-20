defmodule CsvEditor.Query.Update do

  defstruct values: []

  def set(header, value) do
    %__MODULE__{values: [{header, value}]}
  end

  def set(query, header, value) do
    Map.put(query, :values, [{header, value} | query.values])
  end

end
