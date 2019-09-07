defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessages.UpdateOrders do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  def extract(data) do
    data
    |> Enum.map(fn
      %{"ordStatus" => "Canceled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Canceled,
          transformations: [:snake_case]
        )

      %{"ordStatus" => "Filled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Filled,
          transformations: [:snake_case]
        )

      %{"ordStatus" => "PartiallyFilled"} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled,
          transformations: [:snake_case]
        )

      %{"orderID" => _, "workingIndicator" => true} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.Created,
          transformations: [:snake_case]
        )

      %{"cumQty" => _, "leavesQty" => _} = data ->
        Mapail.map_to_struct(data, ProcessAuth.Messages.UpdateOrders.NewPartialFill,
          transformations: [:snake_case]
        )

      data ->
        {:ok, %ProcessAuth.Messages.UpdateOrders.Unhandled{data: data}}
    end)
    |> Enum.map(fn {:ok, message} -> message end)
  end
end
