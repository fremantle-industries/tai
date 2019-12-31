defmodule Tai.Trading.OrderSubmissions.FactoryTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.OrderSubmissions.Factory
  alias Tai.Trading.OrderSubmissions.Factory

  describe ".build!" do
    [:buy, :sell]
    |> Enum.each(fn side ->
      @side side

      test "#{side} gtc orders" do
        submission = build_submission(@side, :gtc, post_only: true)

        assert %Tai.Trading.Order{} = order = Factory.build!(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.post_only == true
        assert order.time_in_force == :gtc
        assert order.venue_id == :test_exchange_a
        assert order.credential_id == :main
        assert order.product_symbol == :btc_usd
        assert order.product_type == :spot
        assert %Decimal{} = order.price
        assert %Decimal{} = order.qty
        assert %Decimal{} = order.leaves_qty
        assert order.qty == order.leaves_qty
        assert order.cumulative_qty == Decimal.new(0)
        assert order.status == :enqueued
        assert order.close == true
        assert %DateTime{} = order.enqueued_at
      end

      test "#{side} fok orders" do
        submission = build_submission(@side, :fok)

        assert %Tai.Trading.Order{} = order = Factory.build!(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.post_only == false
        assert order.time_in_force == :fok
        assert order.venue_id == :test_exchange_a
        assert order.credential_id == :main
        assert order.product_symbol == :btc_usd
        assert order.product_type == :spot
        assert %Decimal{} = order.price
        assert %Decimal{} = order.qty
        assert %Decimal{} = order.leaves_qty
        assert order.qty == order.leaves_qty
        assert order.cumulative_qty == Decimal.new(0)
        assert order.status == :enqueued
        assert order.close == true
        assert %DateTime{} = order.enqueued_at
      end

      test "#{side} ioc orders" do
        submission = build_submission(@side, :ioc)

        assert %Tai.Trading.Order{} = order = Factory.build!(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.time_in_force == :ioc
        assert order.post_only == false
        assert order.venue_id == :test_exchange_a
        assert order.credential_id == :main
        assert order.product_symbol == :btc_usd
        assert order.product_type == :spot
        assert %Decimal{} = order.price
        assert %Decimal{} = order.qty
        assert %Decimal{} = order.leaves_qty
        assert order.qty == order.leaves_qty
        assert order.cumulative_qty == Decimal.new(0)
        assert order.status == :enqueued
        assert order.close == true
        assert %DateTime{} = order.enqueued_at
      end
    end)
  end

  def build_submission(:buy, :gtc, post_only: post_only) do
    %Tai.Trading.OrderSubmissions.BuyLimitGtc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1"),
      post_only: post_only,
      close: true
    }
  end

  def build_submission(:sell, :gtc, post_only: post_only) do
    %Tai.Trading.OrderSubmissions.SellLimitGtc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1"),
      post_only: post_only,
      close: true
    }
  end

  def build_submission(:buy, :fok) do
    %Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1"),
      close: true
    }
  end

  def build_submission(:sell, :fok) do
    %Tai.Trading.OrderSubmissions.SellLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1"),
      close: true
    }
  end

  def build_submission(:buy, :ioc) do
    %Tai.Trading.OrderSubmissions.BuyLimitIoc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1"),
      close: true
    }
  end

  def build_submission(:sell, :ioc) do
    %Tai.Trading.OrderSubmissions.SellLimitIoc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      product_type: :spot,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1"),
      close: true
    }
  end
end
