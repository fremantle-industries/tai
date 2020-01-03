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

  @venue struct(Tai.Venue, credentials: %{credential_a: %{}, credential_b: %{}})

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "returns an error with the reason for each credential" do
    with_mock Tai.Venues.Client, accounts: fn _venue, _credential_id -> {:error, :timeout} end do
      assert {:error, reasons} = Tai.Venues.Boot.Accounts.hydrate(@venue)
      assert reasons == [credential_a: :timeout, credential_b: :timeout]
    end
  end
end
