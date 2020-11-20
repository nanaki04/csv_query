defmodule CsvEditor.CsvCollection do
  alias CsvEditor.Csv
  alias CsvEditor.Query

  defstruct csv_collection: %{},
    collection_path: ""

  def load(dir) do
    csv_regex = ~r/\.csv$/

    with :ok <- File.cd(dir),
         {:ok, files} <- File.ls()
    do
      csv_list = files
                 |> Enum.filter(fn file -> Regex.match?(csv_regex, file) end)
                 |> Enum.map(fn file -> {file, Task.async(fn -> Csv.load(file) end)} end)
                 |> Enum.map(fn {file, task} -> {file, Task.await(task)} end)
                 |> Enum.filter(fn
                   {_, {:ok, _}} -> true
                   _ -> false
                 end)
                 |> Enum.map(fn {file, {:ok, csv}} ->
                   {String.replace(file, csv_regex, ""), csv}
                 end)
                 |> Enum.into(%{})

      csv_collection = %__MODULE__{
        csv_collection: csv_list,
        collection_path: dir
      }

      {:ok, csv_collection}
    else
      error ->
        error
    end
  end

  def save(%__MODULE__{} = csv_collection) do
    csv_collection.csv_collection
    |> Enum.filter(fn {_, csv} -> csv.dirty end)
    |> Enum.map(fn {name, csv} -> {name, Task.async(fn -> Csv.save(csv) end)} end)
    |> Enum.map(fn {name, task} -> {name, Task.await(task)} end)
    |> Enum.filter(fn
      {_, {:ok, _}} -> true
      _ -> false
    end)
    |> Enum.reduce(csv_collection, fn {name, {:ok, csv}}, acc ->
      col = Map.put(acc.csv_collection, name, csv)
      Map.put(acc, :csv_collection, col)
    end)
  end

  def desc(%__MODULE__{} = csv_collection, table) do
    case table(csv_collection, table) do
      {:ok, csv} -> {:ok, {csv.name, csv.headers}}
      _ -> {:error, :table_not_found}
    end
  end

  def table(%__MODULE__{} = csv_collection, table) do
    case Map.fetch(csv_collection.csv_collection, table) do
      {:ok, csv} ->
        {:ok, csv}
      _ ->
        with {:ok, table_name} <- find_table(csv_collection, table),
             {:ok, csv} <- Map.fetch(csv_collection.csv_collection, table_name)
        do
          {:ok, csv}
        else
          _ ->
            {:error, :table_not_found}
        end
    end
  end

  def tables(%__MODULE__{} = csv_collection) do
    Map.keys(csv_collection.csv_collection)
  end

  def find_tables(csv_collection, pattern) do
    with {:ok, regex} <- Regex.compile(pattern) do
      tables(csv_collection)
      |> Enum.filter(fn table -> Regex.match?(regex, table) end)
      |> (& {:ok, &1}).()
    else
      _ ->
        {:error, :invalid_pattern}
    end
  end

  def find_table(csv_collection, pattern) do
    case find_tables(csv_collection, pattern) do
      {:ok, [head | _]} -> {:ok, head}
      {:ok, []} -> {:error, :no_match}
      error -> error
    end
  end

  def query(%__MODULE__{} = csv_collection, %Query{} = query) do
    case table(csv_collection, query.select.table) do
      {:ok, csv} ->
        case Csv.query(csv, query) do
          {:ok, %Csv{} = csv} ->
            col = Map.put(csv_collection.csv_collection, query.select.table, csv)
            {:ok, Map.put(csv_collection, :csv_collection, col)}
          query_result ->
            query_result
        end
      error ->
        error
    end
  end
end
