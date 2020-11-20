defmodule CsvEditor do
  alias CsvEditor.CsvCollection
  alias CsvEditor.Query

  def edit(dir) do
    {:ok, current_dir} = File.cwd()
    {:ok, csv_collection} = CsvCollection.load(dir)
    command_loop(csv_collection)
    File.cd(current_dir)
  end

  defp command_loop(csv_collection) do
    case String.replace(IO.gets("> "), "\n", "") do
      "quit" ->
        csv_collection
      "q" ->
        csv_collection
      "save" ->
        IO.puts("Saving...")
        csv_collection = CsvCollection.save(csv_collection)
        IO.puts("Csv collection saved")
        command_loop(csv_collection)
      "ls" ->
        CsvCollection.tables(csv_collection)
        |> format_list()

        command_loop(csv_collection)
      "ls " <> pattern ->
        case CsvCollection.find_tables(csv_collection, pattern) do
          {:ok, tables} ->
            format_list(tables)
          error ->
            IO.inspect(error)
        end

        command_loop(csv_collection)
      "desc " <> table ->
        case CsvCollection.desc(csv_collection, table) do
          {:ok, {table_name, description}} ->
            IO.puts("#{table_name}")
            format_list(description)
          error ->
            IO.inspect(error)
        end

        command_loop(csv_collection)
      query_str ->
        query = Query.parse(query_str)
        case CsvCollection.query(csv_collection, query) do
          {:ok, %CsvCollection{} = csv_collection} ->
            IO.puts("updated")
            command_loop(csv_collection)
          {:ok, [head | _] = result} ->
            max_length = Map.keys(head)
                         |> max_item_length()

            Enum.reduce(result, 0, fn record, acc ->
              IO.puts("")

              max_value_length = Map.values(record)
                                 |> max_item_length()

              bg = case rem(acc, 2) do
                     0 -> IO.ANSI.color_background(0, 1, 1)
                     1 -> IO.ANSI.color_background(0, 1, 2)
                   end

              case Map.fetch(record, "id") do
                {:ok, id} ->
                  table_header = "#{query.select.table} id: #{id}"
                                 |> String.pad_trailing(max_length + max_value_length + 6)
                  IO.puts("#{bg}#{table_header}#{IO.ANSI.reset}")
                _ ->
                  table_header = "#{query.select.table} index: #{acc}"
                                 |> String.pad_trailing(max_length + max_value_length + 6)
                  IO.puts("#{bg}#{table_header}#{IO.ANSI.reset}")
              end

              Enum.reduce(record, 0, fn {header, value}, i ->

                header = String.pad_trailing("#{header}:", max_length + 1)
                value = String.pad_trailing("#{value}", max_value_length + 2)

                bg = case rem(i, 2) do
                       0 -> IO.ANSI.color_background(0, 0, 0)
                       1 -> bg
                     end

                IO.puts("#{bg}  #{header} #{IO.ANSI.bright}#{value}#{IO.ANSI.reset}")

                i + 1
              end)

              acc + 1
            end)
            command_loop(csv_collection)
          {:ok, []} ->
            IO.puts("no match")
            command_loop(csv_collection)
          error ->
            IO.inspect(error)
            command_loop(csv_collection)
        end
    end
  end

  defp max_item_length(items) do
    Enum.reduce(items, 0, fn item, acc -> max(acc, String.length(item)) end)
  end

  defp format_list(items) do
    max_length = max_item_length(items)

    Enum.reduce(items, 0, fn header, i ->
      bg = case rem(i, 2) do
             0 -> IO.ANSI.color_background(0, 0, 0)
             1 -> IO.ANSI.color_background(0, 1, 1)
           end

      header = String.pad_trailing(header, max_length + 1)
      IO.puts("#{bg} #{header}#{IO.ANSI.reset}")

      i + 1
    end)
  end

end
