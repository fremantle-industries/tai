defmodule Tai.Venues.Boot.AccountsTest do
  use ExUnit.Case, async: false
  import Mock

  defmodule MyAdapter do
    def products(_) do
      products = [
        struct(Tai.Venues.Product, symbol: :btc_usd),
        struct(Tai.Venues.Product, symbol: :eth_usd)
      ]

      {:ok, products}
    end
  end

  @credential_a_accounts [
    struct(Tai.Venues.Account,
      venue_id: :venue_a,
      credential_id: :credential_a,
      asset: :btc,
      type: :spot
    ),
    struct(Tai.Venues.Account,
      venue_id: :venue_a,
      credential_id: :credential_a,
      asset: :eth,
      type: :spot
    )
  ]
  @credential_b_accounts [
    struct(Tai.Venues.Account,
      venue_id: :venue_a,
      credential_id: :credential_b,
      asset: :btc,
      type: :spot
    ),
    struct(Tai.Venues.Account,
      venue_id: :venue_a,
      credential_id: :credential_b,
      asset: :btc,
      type: :swap
    ),
    struct(Tai.Venues.Account,
      venue_id: :venue_a,
      credential_id: :credential_b,
      asset: :ltc,
      type: :spot
    )
  ]

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "returns an error with the reason for each credential" do
    venue =
      struct(Tai.Venue,
        id: :venue_a,
        credentials: %{credential_a: %{}, credential_b: %{}}
      )

    with_mock Tai.Venues.Client, accounts: fn _venue, _credential_id -> {:error, :timeout} end do
      assert {:error, reasons} = Tai.Venues.Boot.Accounts.hydrate(venue)
      assert reasons == [credential_a: :timeout, credential_b: :timeout]
    end
  end

  test "can filter accounts by asset with a juice query" do
    venue =
      struct(Tai.Venue,
        id: :venue_a,
        accounts: "btc ltc",
        credentials: %{credential_a: %{}, credential_b: %{}}
      )

    with_mock Tai.Venues.Client,
      accounts: fn
        _venue, :credential_a -> {:ok, @credential_a_accounts}
        _venue, :credential_b -> {:ok, @credential_b_accounts}
      end do
      assert :ok = Tai.Venues.Boot.Accounts.hydrate(venue)

      accounts = Tai.Venues.AccountStore.all()
      assert Enum.count(accounts) == 4

      assets = Enum.map(accounts, & &1.asset)
      assert Enum.member?(assets, :btc)
      assert Enum.member?(assets, :ltc)
      assert assets |> Enum.filter(&(&1 == :btc)) |> Enum.count() == 3
      assert assets |> Enum.filter(&(&1 == :ltc)) |> Enum.count() == 1
    end
  end

  test "can filter accounts with a custom function" do
    venue =
      struct(Tai.Venue,
        id: :venue_a,
        accounts: fn accounts ->
          Enum.filter(accounts, &(&1.asset == :eth or &1.asset == :ltc))
        end,
        credentials: %{credential_a: %{}, credential_b: %{}}
      )

    with_mock Tai.Venues.Client,
      accounts: fn
        _venue, :credential_a -> {:ok, @credential_a_accounts}
        _venue, :credential_b -> {:ok, @credential_b_accounts}
      end do
      assert :ok = Tai.Venues.Boot.Accounts.hydrate(venue)

      accounts = Tai.Venues.AccountStore.all()
      assert Enum.count(accounts) == 2

      assets = Enum.map(accounts, & &1.asset)
      assert Enum.member?(assets, :eth)
      assert Enum.member?(assets, :ltc)
    end
  end
end
