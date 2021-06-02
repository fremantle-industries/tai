defmodule Tai.Advisors.InstancesTest do
  use Tai.TestSupport.DataCase, async: false
  import Support.Advisors, only: [insert_spec: 1]

  setup do
    insert_spec(%{group_id: :group_a, advisor_id: :main})
    insert_spec(%{group_id: :group_b, advisor_id: :main})
    :ok
  end

  test ".where filters instances from the store" do
    instances = Tai.Advisors.Instances.where([group_id: :group_a])

    assert Enum.count(instances) == 1
    assert [instance | _] = instances
    assert instance.group_id == :group_a
  end

  test ".start supervises the unstarted instances" do
    instances = Tai.Advisors.Instances.where([])

    assert Tai.Advisors.Instances.start(instances) == {2, 0}
    assert Tai.Advisors.Instances.start(instances) == {0, 2}
  end

  test ".stop terminates the supervised instances" do
    unstarted_instances = Tai.Advisors.Instances.where([])
    assert Tai.Advisors.Instances.stop(unstarted_instances) == {0, 2}

    Tai.Advisors.Instances.start(unstarted_instances)

    instances = Tai.Advisors.Instances.where([])
    assert Tai.Advisors.Instances.stop(instances) == {2, 0}
    assert Tai.Advisors.Instances.stop(instances) == {0, 2}
  end
end
