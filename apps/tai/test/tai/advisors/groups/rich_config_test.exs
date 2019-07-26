defmodule Tai.Advisors.Groups.RichConfigTest do
  use ExUnit.Case, async: true
  alias Tai.Advisors.Groups.RichConfig

  defmodule TestProvider do
    @product_a struct(Tai.Venues.Product, venue_id: :venue_a, symbol: :btc_usd)
    @product_b struct(Tai.Venues.Product, venue_id: :venue_a, symbol: :ltc_usd)
    @product_c struct(Tai.Venues.Product, venue_id: :venue_b, symbol: :btc_usd)

    @fee_a struct(Tai.Venues.FeeInfo, venue_id: :venue_a, symbol: :btc_usd, account_id: :main)
    @fee_b struct(Tai.Venues.FeeInfo, venue_id: :venue_a, symbol: :ltc_usd, account_id: :main)
    @fee_c struct(Tai.Venues.FeeInfo, venue_id: :venue_b, symbol: :btc_usd, account_id: :main)

    def products do
      [@product_a, @product_b, @product_c]
    end

    def fees do
      [@fee_a, @fee_b, @fee_c]
    end
  end

  describe ".parse" do
    test "can substitute decimals" do
      config = %{premium: {"-0.3", :decimal}}

      assert rich_config = RichConfig.parse(config, TestProvider)
      assert rich_config.premium == Decimal.new("-0.3")
    end

    test "can substitute products from provider" do
      config = %{product_a: {{:venue_a, :btc_usd}, :product}}

      assert rich_config = RichConfig.parse(config, TestProvider)
      assert %Tai.Venues.Product{} = rich_config.product_a
      assert rich_config.product_a.venue_id == :venue_a
      assert rich_config.product_a.symbol == :btc_usd
    end

    test "can substitute fees from provider" do
      config = %{fee_a: {{:venue_a, :btc_usd, :main}, :fee}}

      assert rich_config = RichConfig.parse(config, TestProvider)
      assert %Tai.Venues.FeeInfo{} = rich_config.fee_a
      assert rich_config.fee_a.venue_id == :venue_a
      assert rich_config.fee_a.symbol == :btc_usd
      assert rich_config.fee_a.account_id == :main
    end
  end
end
