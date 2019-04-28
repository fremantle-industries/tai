defmodule Tai.Trading.BuildOrderFromSubmission do
  alias Tai.Trading.{Order, OrderSubmissions}

  @type order :: Order.t()
  @type submission ::
          OrderSubmissions.BuyLimitGtc.t()
          | OrderSubmissions.SellLimitGtc.t()
          | OrderSubmissions.BuyLimitFok.t()
          | OrderSubmissions.SellLimitFok.t()
          | OrderSubmissions.BuyLimitIoc.t()
          | OrderSubmissions.SellLimitIoc.t()

  @zero Decimal.new(0)

  @spec build!(submission) :: order | no_return
  def build!(submission) do
    qty = Decimal.abs(submission.qty)

    %Order{
      client_id: Ecto.UUID.generate(),
      venue_id: submission.venue_id,
      account_id: submission.account_id,
      product_symbol: submission.product_symbol,
      product_type: submission.product_type,
      side: submission |> side,
      type: submission |> type,
      price: submission.price |> Decimal.abs(),
      avg_price: @zero,
      qty: qty,
      leaves_qty: qty,
      cumulative_qty: @zero,
      time_in_force: submission |> time_in_force,
      post_only: submission |> post_only,
      status: :enqueued,
      enqueued_at: Timex.now(),
      order_updated_callback: submission.order_updated_callback
    }
  end

  defp type(%OrderSubmissions.BuyLimitGtc{}), do: :limit
  defp type(%OrderSubmissions.BuyLimitFok{}), do: :limit
  defp type(%OrderSubmissions.BuyLimitIoc{}), do: :limit
  defp type(%OrderSubmissions.SellLimitGtc{}), do: :limit
  defp type(%OrderSubmissions.SellLimitFok{}), do: :limit
  defp type(%OrderSubmissions.SellLimitIoc{}), do: :limit

  defp side(%OrderSubmissions.BuyLimitGtc{}), do: :buy
  defp side(%OrderSubmissions.BuyLimitFok{}), do: :buy
  defp side(%OrderSubmissions.BuyLimitIoc{}), do: :buy
  defp side(%OrderSubmissions.SellLimitGtc{}), do: :sell
  defp side(%OrderSubmissions.SellLimitFok{}), do: :sell
  defp side(%OrderSubmissions.SellLimitIoc{}), do: :sell

  defp time_in_force(%OrderSubmissions.BuyLimitGtc{}), do: :gtc
  defp time_in_force(%OrderSubmissions.BuyLimitFok{}), do: :fok
  defp time_in_force(%OrderSubmissions.BuyLimitIoc{}), do: :ioc
  defp time_in_force(%OrderSubmissions.SellLimitGtc{}), do: :gtc
  defp time_in_force(%OrderSubmissions.SellLimitFok{}), do: :fok
  defp time_in_force(%OrderSubmissions.SellLimitIoc{}), do: :ioc

  defp post_only(%OrderSubmissions.BuyLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%OrderSubmissions.BuyLimitFok{}), do: false
  defp post_only(%OrderSubmissions.BuyLimitIoc{}), do: false
  defp post_only(%OrderSubmissions.SellLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%OrderSubmissions.SellLimitFok{}), do: false
  defp post_only(%OrderSubmissions.SellLimitIoc{}), do: false
end
