defmodule Tai.NewOrders.OrderTransitionWorker do
  use GenServer
  alias Tai.NewOrders.{Services, Order}

  @moduledoc """
  The OrderTransitionWorker acts as a locking mechanism to ensure an order
  can only be updated sequentially to avoid race conditions when receiving
  the accepted response from a request and asynchronously receiving the result
  of that request.

  Below is an example of the sequence that can occur when creating an order:

  send HTTP request to create order ->
                                      <- asynchronously receive on stream that order created successfully
                                       <- response from HTTP request that create order was accepted

  Multiple orders can be updated in parallel by using 2 or more workers. Orders
  are deterministically sent to the same worker using the following algorithm.

  ```
  hash(order.client_id) % order_transition_worker_count
  ```
  """

  @type order :: Order.t()
  @type client_id :: Order.client_id()
  @type attrs :: Services.ApplyOrderTransition.attrs()

  @spec start_link(pos_integer) :: GenServer.on_start()
  def start_link(idx) do
    name = process_name(idx)
    GenServer.start_link(__MODULE__, idx, name: name)
  end

  @spec process_name(pos_integer) :: atom
  def process_name(idx), do: :"#{__MODULE__}_#{idx}"

  @spec apply(client_id, attrs) :: {:ok, order} | {:error, term}
  def apply(client_id, transition_attrs) do
    client_id
    |> worker_idx()
    |> process_name()
    |> GenServer.call({:apply, client_id, transition_attrs})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:apply, client_id, transition_attrs}, _from, state) do
    result = Services.ApplyOrderTransition.call(client_id, transition_attrs)
    {:reply, result, state}
  end

  defp worker_idx(client_id) do
    config = Tai.Config.parse()
    hash = Murmur.hash_x86_32(client_id)
    rem(hash, config.order_transition_workers)
  end
end
