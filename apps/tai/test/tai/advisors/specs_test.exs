defmodule Tai.Advisors.SpecsTest do
  use ExUnit.Case, async: false
  import Support.Advisors, only: [insert_spec: 2]

  @test_store_id __MODULE__

  setup do
    start_supervised!({Tai.Advisors.Supervisor, []})
    start_supervised!({Tai.Advisors.SpecStore, id: @test_store_id})
    insert_spec(%{group_id: :group_a, advisor_id: :main}, @test_store_id)
    insert_spec(%{group_id: :group_b, advisor_id: :main}, @test_store_id)
    :ok
  end

  test ".where filters instances from the store" do
    specs = Tai.Advisors.Specs.where([group_id: :group_a], @test_store_id)

    assert Enum.count(specs) == 1
    assert [spec | _] = specs
    assert spec.group_id == :group_a
  end
end
