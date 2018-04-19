defmodule Tai.ExchangeAdapters.Poloniex.SnapshotTest do
  use ExUnit.Case, async: true

  alias Tai.ExchangeAdapters.Poloniex.Snapshot

  test "normalize converts a map of prices and sizes into a map of price level tuples" do
    processed_at = Timex.now()
    data = %{"100.1" => "1.2", "100.0" => "0.13"}

    assert Snapshot.normalize(data, processed_at) == %{
             100.0 => {0.13, processed_at, nil},
             100.1 => {1.2, processed_at, nil}
           }
  end
end
