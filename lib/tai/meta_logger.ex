defmodule Tai.MetaLogger do
  def init_pname() do
    pname =
      self()
      |> Process.info()
      |> Keyword.get(:registered_name)

    Logger.metadata(pname: pname)
  end
end
