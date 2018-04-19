defmodule Tai.PubSubTest do
  use ExUnit.Case, async: true
  doctest Tai.PubSub

  alias Tai.PubSub

  defmodule MultiSubscriber do
    use GenServer

    def start_link([id: id, test: test] = state) do
      GenServer.start_link(__MODULE__, state, name: :"#{__MODULE__}_#{id}_#{test}")
    end

    def init(state) do
      PubSub.subscribe([
        :my_topic_a,
        :my_topic_b
      ])

      {:ok, state}
    end

    def handle_call(:unsubscribe, _from, state) do
      PubSub.unsubscribe([
        :my_topic_a,
        :my_topic_b
      ])

      {:reply, :ok, state}
    end

    def handle_info(args, [id: _id, test: test] = state) do
      send(:"test_#{test}", {args, state})

      {:noreply, state}
    end

    def unsubscribe(id) do
      GenServer.call(:"#{__MODULE__}_#{id}_unsubscribe", :unsubscribe)
    end
  end

  test "subscribe can take a single topic" do
    PubSub.subscribe(:my_topic)
    PubSub.broadcast(:my_topic, :my_msg)

    assert_receive :my_msg
  end

  test "subscribe can take multiple topics and broadcast a message to all of them" do
    Process.register(self(), :test_subscribe)
    start_supervised!({MultiSubscriber, id: :a, test: :subscribe}, id: :subscribe_a)
    start_supervised!({MultiSubscriber, id: :b, test: :subscribe}, id: :subscribe_b)

    PubSub.broadcast(:my_topic_a, :my_topic_a_msg)

    assert_receive {:my_topic_a_msg, [id: :a, test: :subscribe]}
    assert_receive {:my_topic_a_msg, [id: :b, test: :subscribe]}

    PubSub.broadcast(:my_topic_b, :my_topic_b_msg)

    assert_receive {:my_topic_b_msg, [id: :a, test: :subscribe]}
    assert_receive {:my_topic_b_msg, [id: :b, test: :subscribe]}
  end

  test "unsubscribe can take a single topic" do
    PubSub.subscribe(:my_topic)
    PubSub.broadcast(:my_topic, :my_msg)

    assert_receive :my_msg

    PubSub.unsubscribe(:my_topic)
    PubSub.broadcast(:my_topic, :my_msg)

    refute_receive :my_msg
  end

  test "unsubscribe can take multiple topics" do
    Process.register(self(), :test_unsubscribe)
    start_supervised!({MultiSubscriber, id: :a, test: :unsubscribe}, id: :subscribe_a)
    start_supervised!({MultiSubscriber, id: :b, test: :unsubscribe}, id: :subscribe_b)

    PubSub.broadcast(:my_topic_a, :my_topic_a_msg)
    PubSub.broadcast(:my_topic_b, :my_topic_b_msg)

    assert_receive {:my_topic_a_msg, [id: :a, test: :unsubscribe]}
    assert_receive {:my_topic_a_msg, [id: :b, test: :unsubscribe]}
    assert_receive {:my_topic_b_msg, [id: :a, test: :unsubscribe]}
    assert_receive {:my_topic_b_msg, [id: :b, test: :unsubscribe]}

    MultiSubscriber.unsubscribe(:b)

    PubSub.broadcast(:my_topic_a, :my_topic_a_msg)
    PubSub.broadcast(:my_topic_b, :my_topic_b_msg)

    assert_receive {:my_topic_a_msg, [id: :a, test: :unsubscribe]}
    refute_receive {:my_topic_a_msg, [id: :b, test: :unsubscribe]}
    assert_receive {:my_topic_b_msg, [id: :a, test: :unsubscribe]}
    refute_receive {:my_topic_b_msg, [id: :b, test: :unsubscribe]}
  end
end
