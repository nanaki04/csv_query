defmodule CsvEditor.CLI do

  def main([]) do
    {:ok, path} = File.cwd()
    CsvEditor.edit(path)
  end

  def main([path]) do
    CsvEditor.edit(path)
  end

end
