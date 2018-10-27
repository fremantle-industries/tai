defmodule Tai.AdvisorsTest do
  use ExUnit.Case, async: true
  doctest Tai.Advisors

  defmodule TestAdvisor do
    use Tai.Advisor
  end

  test ".info returns the pid of each spec if it's running" do
    assert Tai.Advisors.info([]) == []

    spec_1 =
      {TestAdvisor, [group_id: :group_a, advisor_id: :advisor_a, order_books: %{}, store: %{}]}

    spec_2 =
      {TestAdvisor, [group_id: :group_a, advisor_id: :advisor_b, order_books: %{}, store: %{}]}

    start_supervised!(spec_1)

    assert [{^spec_1, pid_1}, {^spec_2, pid_2}] = Tai.Advisors.info([spec_1, spec_2])
    assert is_pid(pid_1)
    assert pid_2 == nil
  end

  test ".start starts specs that aren't already started and returns a count of new & existing" do
    assert Tai.Advisors.start([]) == {:ok, {0, 0}}

    spec_1 =
      {TestAdvisor, [group_id: :group_a, advisor_id: :advisor_a, order_books: %{}, store: %{}]}

    spec_2 =
      {TestAdvisor, [group_id: :group_b, advisor_id: :advisor_b, order_books: %{}, store: %{}]}

    spec_3 =
      {TestAdvisor, [group_id: :group_c, advisor_id: :advisor_b, order_books: %{}, store: %{}]}

    start_supervised!(Tai.AdvisorsSupervisor)
    start_supervised!(spec_1)

    assert Tai.Advisors.start([spec_1, spec_2, spec_3]) == {:ok, {2, 1}}
  end

  test ".stop terminates specs that are running and returns a count of new & existing" do
    assert Tai.Advisors.stop([]) == {:ok, {0, 0}}

    spec_1 =
      {TestAdvisor, [group_id: :group_a, advisor_id: :advisor_a, order_books: %{}, store: %{}]}

    spec_2 =
      {TestAdvisor, [group_id: :group_b, advisor_id: :advisor_b, order_books: %{}, store: %{}]}

    spec_3 =
      {TestAdvisor, [group_id: :group_c, advisor_id: :advisor_b, order_books: %{}, store: %{}]}

    start_supervised!(Tai.AdvisorsSupervisor)
    start_supervised!(spec_1)

    assert Tai.Advisors.stop([spec_1, spec_2, spec_3]) == {:ok, {1, 2}}
  end
end
