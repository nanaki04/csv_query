defmodule CsvEditor.Query.Copy do

  defstruct insert_at: "append"

  def to(location) do
    %__MODULE__{insert_at: location}
  end

  def to(query, location) do
    Map.put(query, :insert_at, location)
  end

end
