defmodule Tai.Advisors.SpecsTest do
  use Tai.TestSupport.DataCase, async: false
  import Support.Advisors, only: [insert_spec: 1]

  setup do
    insert_spec(%{group_id: :group_a, advisor_id: :main})
    insert_spec(%{group_id: :group_b, advisor_id: :main})
    :ok
  end

  test ".where filters instances from the store" do
    specs = Tai.Advisors.Specs.where([group_id: :group_a])

    assert Enum.count(specs) == 1
    assert [spec | _] = specs
    assert spec.group_id == :group_a
  end
end
