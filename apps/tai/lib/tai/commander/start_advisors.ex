defmodule Tai.Commander.StartAdvisors do
  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type opt :: store_id_opt | where_opt

  @spec execute([opt]) :: {started :: non_neg_integer, already_started :: non_neg_integer}
  def execute(options) do
    Tai.NewAdvisors.start(options)
  end
end
