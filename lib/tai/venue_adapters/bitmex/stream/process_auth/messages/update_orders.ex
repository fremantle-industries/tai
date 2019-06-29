defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders do
  alias __MODULE__

  @type t :: %UpdateOrders{data: [map]}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  def process(message, state) do
    message.data
    |> Enum.map(fn
      %{"ordStatus" => "Canceled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Canceled,
          transformations: [:snake_case]
        )

      %{"ordStatus" => "PartiallyFilled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.PartiallyFilled,
          transformations: [:snake_case]
        )

      %{"ordStatus" => "Filled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Filled,
          transformations: [:snake_case]
        )

      %{"orderID" => _, "workingIndicator" => true} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Created,
          transformations: [:snake_case]
        )

      data ->
        {:ok, %ProcessAuth.Messages.UpdateOrders.Unhandled{data: data}}
    end)
    |> Enum.each(fn {:ok, message} ->
      Task.async(fn -> ProcessAuth.SubMessage.process(message, state) end)
    end)

    {:ok, state}
  end
end
