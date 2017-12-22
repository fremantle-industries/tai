defmodule Tai.Exchanges.Adapters.Bitstamp do
  defdelegate quotes(symbol), to: Tai.Exchanges.Adapters.Bitstamp.Quotes
end
