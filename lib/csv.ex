defmodule CsvEditor.Csv do
  alias CsvEditor.Record
  alias CsvEditor.Query
  alias CsvEditor.Query.Select
  alias CsvEditor.Query.Update
  alias CsvEditor.Query.Copy
  alias CsvEditor.Query.Search

  defstruct headers: [],
    records: [],
    file_path: "",
    name: "",
    dirty: false

  def load(file_path) do
    File.read(file_path)
    |> parse_raw_csv(file_path)
  end

  defp parse_raw_csv({:error, _} = error, _) do
    IO.puts("Unable to parse csv")
    error
  end

  defp parse_raw_csv({:ok, raw_csv}, file_path) do
    [headers | records] = String.split(raw_csv, "\n")
                          |> Enum.map(&String.trim/1)
                          |> Enum.filter(fn line -> line != "" end)

    headers = String.split(headers, ",")
              |> Enum.map(&String.trim/1)
              |> Enum.map(&String.trim(&1, "\""))

    records = Enum.map(records, fn record ->
      values = String.split(record, ",")
               |> Enum.map(&String.trim/1)
               |> Enum.map(&String.trim(&1, "\""))

      Enum.zip(headers, values)
      |> Enum.into(%{})
    end)

    csv = %__MODULE__{
      headers: headers,
      records: records,
      name: String.replace(file_path, ~r/\.csv$/, ""),
      file_path: file_path
    }

    {:ok, csv}
  end

  def save(%__MODULE__{dirty: false} = csv) do
    {:ok, csv}
  end

  def save(%__MODULE__{dirty: true} = csv) do
    headers = csv.headers
              |> Enum.map(fn header -> "\"#{header}\"" end)
              |> Enum.join(",")

    records = csv.records
              |> Enum.map(&Record.serialize(&1, csv.headers))

    raw_csv = [headers | records]
              |> Enum.join("\n")

    with :ok <- File.write(csv.file_path, raw_csv <> "\n") do
      {:ok, Map.put(csv, :dirty, false)}
    else
      error -> error
    end
  end

  def save_as(%__MODULE__{} = csv, file_path) do
    csv
    |> Map.put(:dirty, true)
    |> with_file_path(file_path)
    |> save()
  end

  def with_file_path(%__MODULE__{} = csv, file_path) do
    Map.put(csv, :file_path, file_path)
  end

  def query(csv, id) when is_integer(id) do
    id_str = "#{id}"
    record = Enum.find(csv.records, fn
      %{"id" => ^id_str} -> true
      _ -> false
    end)

    if record == nil do
      Enum.at(csv.records, id)
    else
      record
    end
  end

  def query(csv, %Query{delete: true} = query) do
    delete_query(csv, query)
  end

  def query(csv, %Query{copy: %Copy{}} = query) do
    copy_query(csv, query)
  end

  def query(csv, %Query{update: %Update{}} = query) do
    update_query(csv, query)
  end

  def query(csv, %Query{search: %Search{}} = query) do
    search_query(csv, query)
  end

  def query(csv, %Query{} = query) do
    select_query(csv, query.select)
  end

  def query(csv, header, value) do
    Enum.filter(csv.records, fn record ->
      Map.fetch(record, header) == {:ok, value}
    end)
  end

  def query(csv, id, update_header, update_value) do
    if Enum.member?(csv.headers, "id") do
      query(csv, "id", id, update_header, update_value)
    else
      record = Enum.at(csv.records, id)
               |> Map.put(update_header, update_value)

      records = List.replace_at(csv.records, id, record)
      Map.put(csv, :records, records)
      |> Map.put(:dirty, true)
    end
  end

  def query(csv, header, value, update_header, update_value) do
    records = csv.records
              |> Enum.map(fn record ->
                case record[header] == value do
                  true ->
                    Map.put(record, update_header, update_value)
                  _ ->
                    record
                end
              end)

    Map.put(csv, :records, records)
    |> Map.put(:dirty, true)
  end

  defp select_query(csv, %Select{} = query) do
    records = evaluate_where_clause(csv.records, query)

    result = case query.values do
               [] ->
                 records
               values ->
                 Enum.map(records, fn record -> Map.take(record, values) end)
             end

    if query.distinct do
      Enum.uniq(result)
    else
      result
    end
    |> (& {:ok, &1}).()
  end

  defp update_query(csv, %Query{} = query) do
    {records, _} = Enum.reduce(csv.records, {[], 0}, fn record, {records, idx} ->
                     case Record.evaluate_where_clause(record, query.select.where, idx) do
                       false ->
                         {[record | records], idx + 1}
                       true ->
                         record = Enum.reduce(query.update.values, record, fn
                                    {header, value}, acc -> Map.put(acc, header, value)
                                  end)

                         {[record | records], idx + 1}
                     end
                   end)

    records = Enum.reverse(records)

    Map.put(csv, :records, records)
    |> Map.put(:dirty, true)
    |> (& {:ok, &1}).()
  end

  defp copy_query(csv, query) do
    records = evaluate_where_clause(csv.records, query.select)

    case records do
      [] ->
        {:error, :no_copy_target}
      [head | _] ->
        copy = if Enum.member?(csv.headers, "id") do
                 max_id = Enum.reduce(csv.records, 1, fn record, acc ->
                            with {:ok, id} <- Map.fetch(record, "id"),
                                 {id_int, _} <- Integer.parse(id)
                            do
                              max(acc, id_int)
                            else
                              _ ->
                                acc
                            end
                          end)

                 Map.put(head, "id", "#{max_id + 1}")
               else
                 head
               end

        records = case query.copy.insert_at do
                    "append" ->
                      [copy | Enum.reverse(csv.records)]
                      |> Enum.reverse()
                    "prepend" ->
                      [copy | csv.records]
                    index ->
                      {idx, ""} = Integer.parse(index)
                      List.insert_at(csv.records, idx, copy)
                  end

        Map.put(csv, :records, records)
        |> Map.put(:dirty, true)
        |> (& {:ok, &1}).()
    end
  end

  defp delete_query(csv, query) do
    records = evaluate_where_clause(csv.records, query.select, true)

    Map.put(csv, :records, records)
    |> Map.put(:dirty, true)
    |> (& {:ok, &1}).()
  end

  defp search_query(csv, query = %{search: %{key_term: key_term}}) do
    Enum.filter(csv.records, fn record ->
      Record.evaluate_key_value_terms(record, key_term, query.search.value_term)
    end)
    |> (& {:ok, &1}).()
  end

  defp search_query(csv, query) do
    Enum.filter(csv.records, fn record ->
      Record.evaluate_value_term(record, query.search.value_term)
    end)
    |> (& {:ok, &1}).()
  end

  defp evaluate_where_clause(records, query, inverse \\ false) do
    {records, _} = Enum.reduce(records, {[], 0}, fn record, {records, idx} ->
                     result = Record.evaluate_where_clause(record, query.where, idx)
                     if (result && !inverse) || (inverse && !result) do
                       {[record | records], idx + 1}
                     else
                       {records, idx + 1}
                     end
                   end)

    Enum.reverse(records)
  end

end
