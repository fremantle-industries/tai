defmodule Tai.Events.OrderUpdatedTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.OrderUpdated{
      client_id: "my_client_id",
      venue_id: :my_venue,
      account_id: :my_account,
      product_symbol: :btc,
      side: :buy,
      type: :limit,
      time_in_force: :gtc,
      status: :open,
      price: Decimal.new("0.1"),
      size: Decimal.new("0.2"),
      executed_size: Decimal.new("0.3"),
      error_reason: :my_error_reason
    }

    assert Tai.LogEvent.to_data(event) == %{
             client_id: "my_client_id",
             venue_id: :my_venue,
             account_id: :my_account,
             product_symbol: :btc,
             side: :buy,
             type: :limit,
             time_in_force: :gtc,
             status: :open,
             price: "0.1",
             size: "0.2",
             executed_size: "0.3",
             error_reason: :my_error_reason
           }
  end
end
