defmodule Tai.MetaLogger do
  def init_tid() do
    tid =
      self()
      |> Process.info()
      |> Keyword.get(:registered_name)

    Logger.metadata(tid: tid)
  end
end
