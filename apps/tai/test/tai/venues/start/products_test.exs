defmodule Tai.Venues.Start.ProductsTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule TestAdapter do
    use Support.StartVenueAdapter

    @product_a struct(
                 Tai.Venues.Product,
                 venue_id: :venue_a,
                 symbol: :btc_usdt
               )
    @product_b struct(
                 Tai.Venues.Product,
                 venue_id: :venue_a,
                 symbol: :eth_usdt
               )
    @product_c struct(
                 Tai.Venues.Product,
                 venue_id: :venue_a,
                 symbol: :ltc_usdt_200925,
                 base: :ltc,
                 quote: :usdt,
                 alias: "weekly"
               )

    def products(_venue_id) do
      {:ok, [@product_a, @product_b, @product_c]}
    end
  end

  defmodule MaintenanceErrorAdapter do
    use Support.StartVenueAdapter

    def products(_venue_id) do
      {:error, :maintenance}
    end
  end

  defmodule RaiseErrorAdapter do
    use Support.StartVenueAdapter

    def products(_venue_id) do
      raise "raise_error_for_products"
    end
  end

  defmodule ProductsFilter do
    def run(products), do: Enum.filter(products, &(&1.symbol == :btc_usdt))
  end

  defmodule ArgumentedProductsFilter do
    def run(products, symbol), do: Enum.filter(products, &(&1.symbol == symbol))
  end

  @base_venue struct(
                Tai.Venue,
                adapter: TestAdapter,
                id: :venue_a,
                credentials: %{},
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

  test "can filter products by symbol with a juice query" do
    venue = @base_venue |> Map.put(:products, "eth_usdt")
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    products = Tai.Venues.ProductStore.all()
    assert Enum.count(products) == 1
    assert Enum.at(products, 0).symbol == :eth_usdt
  end

  test "can filter products by base, quote & alias with a juice query" do
    venue = @base_venue |> Map.put(:products, "ltc_usdt_weekly")
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    products = Tai.Venues.ProductStore.all()
    assert Enum.count(products) == 1
    assert Enum.at(products, 0).symbol == :ltc_usdt_200925
  end

  test "can filter products with a module function" do
    venue = @base_venue |> Map.put(:products, {ProductsFilter, :run})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    products = Tai.Venues.ProductStore.all()
    assert Enum.count(products) == 1
    assert Enum.at(products, 0).symbol == :btc_usdt
  end

  test "can filter products with a module function with arguments" do
    venue = @base_venue |> Map.put(:products, {ArgumentedProductsFilter, :run, [:btc_usdt]})

    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    products = Tai.Venues.ProductStore.all()
    assert Enum.count(products) == 1
    assert Enum.at(products, 0).symbol == :btc_usdt
  end

  test "broadcasts a summary event of unique products matching the filter" do
    venue = @base_venue |> Map.put(:products, "*")
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.HydrateProducts{} = event, :info)
    assert event.venue_id == venue.id
    assert event.total == 3
    assert event.filtered == 3
  end

  test "broadcasts a start error event when the adapter returns an error" do
    venue = @base_venue |> Map.put(:adapter, MaintenanceErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert event.reason == [products: :maintenance]
  end

  test "broadcasts a start error event when the adapter raises an error" do
    venue = @base_venue |> Map.put(:adapter, RaiseErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert [products: {error, stacktrace}] = event.reason
    assert error == %RuntimeError{message: "raise_error_for_products"}
    assert Enum.count(stacktrace) > 0
  end
end
