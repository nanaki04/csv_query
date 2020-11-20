defmodule CsvEditor.Query do
  alias CsvEditor.Query.Select
  alias CsvEditor.Query.Update
  alias CsvEditor.Query.Copy

  @select_regex ~r/(select.+)($|from|set|where)/U
  @from_regex ~r/(from.+)($|where)/U
  @where_regex ~r/(where.+)($|from|set)/U
  @update_regex ~r/(update.+)($|where|set)/U
  @set_regex ~r/(set.+)($|where)/U
  @copy_regex ~r/(copy.+)($|from|where)/U
  @to_regex ~r/(to.+)($|from|where)/U

  defstruct select: %Select{},
    update: nil,
    copy: nil

  def new() do
    %__MODULE__{}
  end

  def from(table) do
    query = new()
    from(query, table)
  end

  def from(query, table) do
    select = Select.from(query.select, table)
    Map.put(query, :select, select)
  end

  def value(val) do
    query = new()
    value(query, val)
  end

  def value(query, val) do
    select = Select.value(query.select, val)
    Map.put(query, :select, select)
  end

  def values(vals) do
    query = new()
    values(query, vals)
  end

  def values(query, vals) do
    select = Select.values(query.select, vals)
    Map.put(query, :select, select)
  end

  def where(column, val) do
    query = new()
    where(query, column, val)
  end

  def where(query, column, val) do
    select = Select.where(query.select, column, val)
    Map.put(query, :select, select)
  end

  def distinct(query) do
    select = Select.distinct(query.select)
    Map.put(query, :select, select)
  end

  def set(header, value) do
    query = new()
    set(query, header, value)
  end

  def set(%__MODULE__{update: nil} = query, header, value) do
    update = Update.set(header, value)
    Map.put(query, :update, update)
  end

  def set(%__MODULE__{update: update} = query, header, value) do
    update = Update.set(update, header, value)
    Map.put(query, :update, update)
  end

  def to(%__MODULE__{copy: %Copy{}} = query, to) do
    copy = Copy.to(query.copy, to)
    Map.put(query, :copy, copy)
  end

  def to(%__MODULE__{} = query, to) do
    copy = Copy.to(to)
    Map.put(query, :copy, copy)
  end

  def parse(query_str) do
    new()
    |> parse_select(query_str)
    |> parse_update(query_str)
    |> parse_copy(query_str)
    |> parse_from(query_str)
    |> parse_where(query_str)
    |> parse_set(query_str)
    |> parse_to(query_str)
  end

  defp parse_select(query, query_str) do
    case Regex.run(@select_regex, query_str) do
      [_ | [select | _]] ->
        vals = String.split(select, " ")
               |> tl()
               |> Enum.map(&String.trim/1)
               |> Enum.filter(fn val -> val != "" end)

        case vals do
          ["distinct" | vals] ->
            distinct(query)
            |> values(vals)
          vals ->
            values(query, vals)
        end
      _ ->
        query
    end
  end

  defp parse_update(query, query_str) do
    case Regex.run(@update_regex, query_str) do
      [_ | [update | _]] ->
        [_ | [table | _]] = String.split(update, " ")
                            |> Enum.map(&String.trim/1)

        from(query, table)
      _ ->
        query
    end
  end

  defp parse_copy(query, query_str) do
    case Regex.run(@copy_regex, query_str) do
      [_ | [copy_query | _]] ->
        opts = String.split(copy_query, " ")
               |> Enum.map(&String.trim/1)
               |> Enum.filter(fn val -> val != "" end)
               |> tl()

        case opts do
          [] -> Map.put(query, :copy, %Copy{})
          [opt] -> to(query, opt)
        end
      _ ->
        query
    end
  end

  defp parse_from(query, query_str) do
    case Regex.run(@from_regex, query_str) do
      [_ | [frm | _]] ->
        [_ | [table | _]] = String.split(frm, " ")
                            |> Enum.map(&String.trim/1)

        from(query, table)
      _ ->
        query
    end
  end

  defp parse_where(query, query_str) do
    case Regex.run(@where_regex, query_str) do
      [_ | [where_query | _]] ->
        String.split(where_query, " ")
        |> tl()
        |> Enum.filter(fn el -> el != "" end)
        |> Enum.map(&String.trim/1)
        |> Enum.chunk_every(3)
        |> Enum.reduce(query, fn
          [header, "=", value], acc ->
            where(acc, header, value)
          _, acc ->
            IO.warn("unexpected where clause")
            acc
        end)
      _ ->
        query
    end
  end

  defp parse_set(query, query_str) do
    case Regex.run(@set_regex, query_str) do
      [_ | [set_query | _]] ->
        String.split(set_query, " ")
        |> tl()
        |> Enum.filter(fn el -> el != "" end)
        |> Enum.map(&String.trim/1)
        |> Enum.chunk_every(3)
        |> Enum.reduce(query, fn
          [header, "=", value], acc ->
            set(acc, header, value)
          _, acc ->
            IO.warn("unexpected set clause")
            acc
        end)
      _ ->
        query
    end
  end

  defp parse_to(query, query_str) do
    case Regex.run(@to_regex, query_str) do
      [_ | [to_query | _]] ->
        [target] = String.split(to_query, " ")
                 |> Enum.map(&String.trim/1)
                 |> Enum.filter(fn val -> val != "" end)
                 |> tl()

        to(query, target)
      _ ->
        query
    end
  end

end
