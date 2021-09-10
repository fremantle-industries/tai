defmodule Tai.Commander.StopAdvisors do
  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type opt :: store_id_opt | where_opt

  @spec execute([opt]) :: {stopped :: non_neg_integer, already_stopped :: non_neg_integer}
  def execute(options) do
    Tai.Advisors.stop(options)
  end
end
