defmodule Tai.Venues.Start.FeesTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule ProductWithFeesAdapter do
    use Support.StartVenueAdapter

    @product struct(
               Tai.Venues.Product,
               venue_id: :venue_a,
               symbol: :btc_usdt,
               maker_fee: Decimal.new("0.0001"),
               taker_fee: Decimal.new("0.0002")
             )

    def products(_venue_id) do
      {:ok, [@product]}
    end

    def maker_taker_fees(_venue_id, _credential_id, _credentials) do
      {:ok, {Decimal.new("0.0005"), Decimal.new("0.001")}}
    end
  end

  defmodule NoProductFeesAdapter do
    use Support.StartVenueAdapter

    @product struct(
               Tai.Venues.Product,
               venue_id: :venue_a,
               symbol: :btc_usdt
             )

    def products(_venue_id) do
      {:ok, [@product]}
    end

    def maker_taker_fees(_venue_id, _credential_id, _credentials) do
      {:ok, {Decimal.new("0.0005"), Decimal.new("0.001")}}
    end
  end

  defmodule NoScheduleFeesAdapter do
    use Support.StartVenueAdapter

    @product struct(
               Tai.Venues.Product,
               venue_id: :venue_a,
               symbol: :btc_usdt,
               maker_fee: Decimal.new("0.0001"),
               taker_fee: Decimal.new("0.0002")
             )

    def products(_venue_id) do
      {:ok, [@product]}
    end

    def maker_taker_fees(_venue_id, _credential_id, _credentials) do
      {:ok, nil}
    end
  end

  defmodule MaintenanceErrorAdapter do
    use Support.StartVenueAdapter

    def maker_taker_fees(_venue_id, _credential_id, _credentials) do
      {:error, :maintenance}
    end
  end

  defmodule RaiseErrorAdapter do
    use Support.StartVenueAdapter

    def maker_taker_fees(_venue_id, _credential_id, _credentials) do
      raise "raise_error_for_fees"
    end
  end

  @base_venue struct(
                Tai.Venue,
                adapter: TestAdapter,
                id: :venue_a,
                credentials: %{main: %{}},
                accounts: "*",
                products: "*",
                timeout: 1_000
              )

  setup do
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Venues.ProductStore)
    start_supervised!(Tai.Venues.AccountStore)
    start_supervised!(Tai.Venues.FeeStore)
    start_supervised!(Tai.Trading.PositionStore)
    start_supervised!(Tai.Venues.StreamsSupervisor)
    :ok
  end

  test "uses the min fee from the product or schedule" do
    venue = @base_venue |> Map.put(:adapter, ProductWithFeesAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStart{} , :info)

    fees = Tai.Venues.FeeStore.all()
    assert Enum.count(fees) == 1
    assert Enum.at(fees, 0).maker == Decimal.new("0.0001")
    assert Enum.at(fees, 0).taker == Decimal.new("0.0002")
  end

  test "uses the fee schedule when the product doesn't have maker/taker fees" do
    venue = @base_venue |> Map.put(:adapter, NoProductFeesAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStart{} , :info)

    fees = Tai.Venues.FeeStore.all()
    assert Enum.count(fees) == 1
    assert Enum.at(fees, 0).maker == Decimal.new("0.0005")
    assert Enum.at(fees, 0).taker == Decimal.new("0.001")
  end

  test "uses the product fees when there is no fee schedule" do
    venue = @base_venue |> Map.put(:adapter, NoScheduleFeesAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStart{} , :info)

    fees = Tai.Venues.FeeStore.all()
    assert Enum.count(fees) == 1
    assert Enum.at(fees, 0).maker == Decimal.new("0.0001")
    assert Enum.at(fees, 0).taker == Decimal.new("0.0002")
  end

  test "broadcasts a start error event when the adapter returns an error" do
    venue = @base_venue |> Map.put(:adapter, MaintenanceErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert event.reason == [fees: [main: :maintenance]]
  end

  test "broadcasts a start error event when the adapter raises an error" do
    venue = @base_venue |> Map.put(:adapter, RaiseErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id

    assert [fees: fee_errors] = event.reason
    assert Enum.count(fee_errors) == 1
    assert [{_, {error, stacktrace}} | _] = fee_errors
    assert error == %RuntimeError{message: "raise_error_for_fees"}
    assert Enum.count(stacktrace) > 0
  end
end
