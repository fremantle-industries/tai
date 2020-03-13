defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdatePosition do
  alias __MODULE__
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type t :: %UpdatePosition{data: map}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    require Logger

    # %{
    #   "account" => 158_677,
    #   "currency" => "XBt",
    #   "currentQty" => 1,
    #   "currentTimestamp" => "2020-03-13T23:30:05.364Z",
    #   "lastPrice" => 5656.81,
    #   "liquidationPrice" => 1,
    #   "maintMargin" => 138,
    #   "markPrice" => 5656.81,
    #   "posComm" => 14,
    #   "posMaint" => 123,
    #   "posMargin" => 5473,
    #   "symbol" => "XBTUSD",
    #   "timestamp" => "2020-03-13T23:30:05.364Z"
    # }

    def process(message, _received_at, _state) do
      Logger.info("================= UPDATE POSITION message data: #{inspect(message.data)}")
      :ok
    end
  end
end
