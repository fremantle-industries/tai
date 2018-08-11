# Tai

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## Log the spread of every order book

```bash
# log/dev.log
2018-08-11T00:07:30.371 [debug] tid=advisor_log_spread_advisor [poloniex,eth_usdt] spread: 0.760000
2018-08-11T00:07:30.418 [debug] tid=advisor_log_spread_advisor [gdax,btc_usd] spread: 0.010000
2018-08-11T00:07:30.508 [debug] tid=advisor_log_spread_advisor [gdax,btc_usd] spread: 0.010000
2018-08-11T00:07:30.603 [debug] tid=advisor_log_spread_advisor [gdax,btc_usd] spread: 0.010000
2018-08-11T00:07:30.814 [debug] tid=advisor_log_spread_advisor [gdax,eth_usd] spread: 0.010000
2018-08-11T00:07:30.821 [debug] tid=advisor_log_spread_advisor [poloniex,btc_usdt] spread: 8.028832
2018-08-11T00:07:30.858 [debug] tid=advisor_log_spread_advisor [binance,eth_usdt] spread: 0.090000
2018-08-11T00:07:30.861 [debug] tid=advisor_log_spread_advisor [binance,btc_usdt] spread: 5.930000
2018-08-11T00:07:30.863 [debug] tid=advisor_log_spread_advisor [binance,ltc_usdt] spread: 0.070000
2018-08-11T00:07:30.979 [debug] tid=advisor_log_spread_advisor [gdax,eth_usd] spread: 0.010000
```

[Example](./log_spread/advisor.ex)

## Create fill or kill orders

[Example](./fill_or_kill_orders/advisor.ex)

## Cancel pending orders

[Example](./create_and_cancel_pending_order/advisor.ex)

## All order book changes

Coming soon...

## Store data for later

Coming soon...
