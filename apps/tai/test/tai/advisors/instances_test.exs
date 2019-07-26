defmodule Tai.Advisors.InstancesTest do
  use ExUnit.Case, async: false
  import Support.Advisors, only: [insert_spec: 2]

  @test_store_id __MODULE__

  setup do
    start_supervised!({Tai.Advisors.Supervisor, []})
    start_supervised!({Tai.Advisors.Store, id: @test_store_id})
    insert_spec(%{group_id: :group_a, advisor_id: :main}, @test_store_id)
    insert_spec(%{group_id: :group_b, advisor_id: :main}, @test_store_id)
    :ok
  end

  test ".where filters instances from the store" do
    instances = Tai.Advisors.Instances.where([group_id: :group_a], @test_store_id)

    assert Enum.count(instances) == 1
    assert [instance | _] = instances
    assert instance.group_id == :group_a
  end

  test ".start supervises the unstarted instances" do
    instances = Tai.Advisors.Instances.where([], @test_store_id)

    assert Tai.Advisors.Instances.start(instances) == {2, 0}
    assert Tai.Advisors.Instances.start(instances) == {0, 2}
  end

  test ".stop terminates the supervised instances" do
    unstarted_instances = Tai.Advisors.Instances.where([], @test_store_id)
    assert Tai.Advisors.Instances.stop(unstarted_instances) == {0, 2}

    Tai.Advisors.Instances.start(unstarted_instances)

    instances = Tai.Advisors.Instances.where([], @test_store_id)
    assert Tai.Advisors.Instances.stop(instances) == {2, 0}
    assert Tai.Advisors.Instances.stop(instances) == {0, 2}
  end
end
