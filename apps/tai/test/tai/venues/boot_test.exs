defmodule Tai.Venues.BootTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.Boot
  alias Tai.TestSupport.Mocks

  setup_all do
    start_supervised!(Mocks.Server)
    :ok
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_id :mock_boot
  @credential_id :main
  @timeout 5000

  describe ".run success" do
    setup [:mock_products, :mock_accounts, :mock_maker_taker_fees]

    @venue struct(Tai.Venue, %{
             id: @venue_id,
             adapter: Tai.VenueAdapters.Mock,
             products: "* -ltc_usdt",
             accounts: "*",
             credentials: %{main: %{}},
             timeout: @timeout
           })

    test "hydrates filtered products" do
      assert {:ok, %Tai.Venue{}} = Tai.Venues.Boot.run(@venue)

      assert {:ok, btc_usdt_product} = Tai.Venues.ProductStore.find({@venue_id, :btc_usdt})
      assert {:ok, eth_usdt_product} = Tai.Venues.ProductStore.find({@venue_id, :eth_usdt})
      assert {:error, :not_found} = Tai.Venues.ProductStore.find({@venue_id, :ltc_usdt})
    end

    test "hydrates accounts" do
      assert {:ok, %Tai.Venue{}} = Tai.Venues.Boot.run(@venue)

      assert {:ok, _btc_account} =
               Tai.Venues.AccountStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 asset: :btc
               )

      assert {:ok, _eth_account} =
               Tai.Venues.AccountStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 asset: :eth
               )

      assert {:ok, _ltc_account} =
               Tai.Venues.AccountStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 asset: :ltc
               )

      assert {:ok, _usdt_account} =
               Tai.Venues.AccountStore.find_by(
                 venue_id: @venue_id,
                 credential_id: :main,
                 asset: :usdt
               )
    end

    test "hydrates fees" do
      assert {:ok, %Tai.Venue{}} = Tai.Venues.Boot.run(@venue)

      assert {:ok, btc_usdt_fee} =
               Tai.Venues.FeeStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 symbol: :btc_usdt
               )

      assert {:ok, eth_usdt_fee} =
               Tai.Venues.FeeStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 symbol: :eth_usdt
               )

      assert {:error, :not_found} =
               Tai.Venues.FeeStore.find_by(
                 venue_id: @venue_id,
                 credential_id: @credential_id,
                 symbol: :ltc_usdt
               )
    end
  end

  describe ".run products hydrate error" do
    test "returns an error tuple" do
      venue =
        struct(Tai.Venue, %{
          id: :mock_boot,
          adapter: Tai.VenueAdapters.Mock,
          products: "*",
          accounts: "*",
          credentials: %{},
          timeout: @timeout
        })

      assert {:error, result} = Tai.Venues.Boot.run(venue)
      assert {result_venue, reasons} = result
      assert result_venue == venue
      assert reasons == [products: :mock_response_not_found]
    end
  end

  describe ".run accounts hydrate error" do
    setup [:mock_products, :mock_maker_taker_fees]

    test "returns an error" do
      venue =
        struct(Tai.Venue, %{
          id: :mock_boot,
          adapter: Tai.VenueAdapters.Mock,
          products: "*",
          accounts: "*",
          credentials: %{main: %{}},
          timeout: @timeout
        })

      assert {:error, result} = Tai.Venues.Boot.run(venue)
      assert {result_venue, reasons} = result
      assert result_venue == venue
      assert reasons == [accounts: [main: :mock_response_not_found]]
    end
  end

  describe ".run fees hydrate error" do
    setup [:mock_products, :mock_accounts]

    test "returns an error" do
      venue =
        struct(Tai.Venue, %{
          id: :mock_boot,
          adapter: Tai.VenueAdapters.Mock,
          products: "*",
          accounts: "*",
          credentials: %{main: %{}},
          timeout: @timeout
        })

      assert {:error, result} = Tai.Venues.Boot.run(venue)
      assert {result_venue, reasons} = result
      assert result_venue == venue
      assert reasons == [fees: :mock_response_not_found]
    end
  end

  def mock_products(_) do
    Mocks.Responses.Products.for_venue(
      @venue_id,
      [
        %{symbol: :btc_usdt},
        %{symbol: :eth_usdt},
        %{symbol: :ltc_usdt}
      ]
    )

    :ok
  end

  def mock_maker_taker_fees(_) do
    Mocks.Responses.MakerTakerFees.for_venue_and_credential(
      @venue_id,
      @credential_id,
      {Decimal.new("0.001"), Decimal.new("0.001")}
    )
  end

  def mock_accounts(_) do
    Mocks.Responses.Accounts.for_venue_and_credential(
      @venue_id,
      @credential_id,
      [
        %{asset: :btc, free: Decimal.new("0.1"), locked: Decimal.new("0.2")},
        %{asset: :eth, free: Decimal.new("0.3"), locked: Decimal.new("0.4")},
        %{asset: :ltc, free: Decimal.new("0.5"), locked: Decimal.new("0.6")},
        %{asset: :usdt, free: Decimal.new(0), locked: Decimal.new(0)}
      ]
    )

    :ok
  end
end
