defmodule Tai.Venues.Start.SuccessTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule TestVenueAdapter do
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

    def products(_venue_id) do
      {:ok, [@product_a, @product_b]}
    end

    def accounts(venue_id, credential_id, _credentials) do
      account_a = build_account(venue_id, credential_id, :btc)
      account_b = build_account(venue_id, credential_id, :eth)
      account_c = build_account(venue_id, credential_id, :ltc)

      {:ok, [account_a, account_b, account_c]}
    end

    def positions(venue_id, credential_id, _credentials) do
      position_a =
        struct(
          Tai.Trading.Position,
          venue_id: venue_id,
          credential_id: credential_id,
          symbol: :btc_usdt
        )

      {:ok, [position_a]}
    end

    def maker_taker_fees(_, _, _) do
      {:ok, {Decimal.new("0.0005"), Decimal.new("0.001")}}
    end

    defp build_account(venue_id, credential_id, asset) do
      struct(
        Tai.Venues.Account,
        venue_id: venue_id,
        credential_id: credential_id,
        asset: asset
      )
    end
  end

  @venue struct(
           Tai.Venue,
           adapter: TestVenueAdapter,
           id: :venue_a,
           credentials: %{main_a: %{}, main_b: %{}, main_c: %{}},
           accounts: "*",
           products: "*",
           market_streams: "*",
           timeout: 100
         )

  test "hydrates venue data and starts the stream" do
    Tai.SystemBus.subscribe({:venue, :start})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, @venue})

    assert_receive {{:venue, :start}, started_venue}
    assert started_venue == @venue.id

    assert_event(%Tai.Events.VenueStart{} = start_event, :info)
    assert start_event.venue == @venue.id

    products = Tai.Venues.ProductStore.all()
    assert Enum.count(products) == 2

    accounts = Tai.Venues.AccountStore.all()
    assert Enum.count(accounts) == 9

    fees = Tai.Venues.FeeStore.all()
    assert Enum.count(fees) == 6

    positions = Tai.Trading.PositionStore.all()
    assert Enum.count(positions) == 3

    assert %{active: active, supervisors: supervisors} =
             DynamicSupervisor.count_children(Tai.Venues.StreamsSupervisor)

    assert active == 1
    assert supervisors == 1

    refute_event(%Tai.Events.VenueStartError{}, :error)
  end
end
