defmodule Tai.IEx.Commands.StartAdvisors do
  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type options :: [store_id_opt | where_opt]

  @spec start(options) :: no_return
  def start(options) do
    {started, already_started} = Tai.Commander.start_advisors(options)
    IO.puts("started advisors new=#{started}, already_running=#{already_started}")
    IEx.dont_display_result()
  end
end
