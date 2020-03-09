defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessage do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type venue_message :: map

  @empty []

  @spec extract(venue_message) :: [struct]
  def extract(msg)

  def extract(%{"table" => "order", "action" => action, "data" => data}) do
    action
    |> case do
      "update" -> ProcessAuth.VenueMessages.UpdateOrders.extract(data)
      _ -> @empty
    end
  end

  def extract(%{"table" => "position", "action" => action, "data" => data}) do
    action
    |> case do
      "insert" -> data |> Enum.map(fn d -> %ProcessAuth.Messages.InsertPosition{data: d} end)
      "update" -> data |> Enum.map(fn d -> %ProcessAuth.Messages.UpdatePosition{data: d} end)
      _ -> @empty
    end
  end

  def extract(%{"table" => "margin", "action" => action, "data" => data}) do
    action
    |> case do
      "update" -> data |> Enum.map(fn d -> %ProcessAuth.Messages.UpdateAccount{data: d} end)
      _ -> @empty
    end
  end

  @empty_tables ~w(transact execution wallet)
  def extract(%{"table" => table}) when table in @empty_tables do
    @empty
  end

  def extract(msg) do
    [%ProcessAuth.Messages.Unhandled{msg: msg}]
  end
end
