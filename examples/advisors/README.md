# Tai

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## Advisors

To run the example advisors included within this repo you will need to start
`tai` with the `EXAMPLES=true` environment variable.

```bash
$ EXAMPLES=true iex -S mix
```

### Log the spread of every order book

```bash
# log/dev.log
09:41:35.950 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"gdax","spread":"0.01","product_symbol":"btc_usd","bid_price":"5491.05","ask_price":"5491.06"}}
09:41:37.211 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"binance","spread":"1.76","product_symbol":"btc_usdt","bid_price":"5620.64","ask_price":"5622.4"}}
09:41:37.686 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"gdax","spread":"0.01","product_symbol":"btc_usd","bid_price":"5491.05","ask_price":"5491.06"}}
09:41:37.862 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"poloniex","spread":"6.75064342","product_symbol":"btc_usdt","bid_price":"5615.60680303","ask_price":"5622.35744645"}}
09:41:38.214 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"binance","spread":"1.77","product_symbol":"btc_usdt","bid_price":"5620.64","ask_price":"5622.41"}}
```

[Example](./log_spread/advisor.ex)

### Create fill or kill orders

[Example](./fill_or_kill_orders/advisor.ex)

### Cancel pending orders

[Example](./create_and_cancel_pending_order/advisor.ex)
