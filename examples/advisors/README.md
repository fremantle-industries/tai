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
2018-10-26T22:31:12.623 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.63936650,6541.11444443,6544.75381093]
2018-10-26T22:31:12.644 [info]  tid=advisor_log_spread_binance_btc_usdt [spread:binance,btc_usdt,0.03,6541.36,6541.39]
2018-10-26T22:31:12.754 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
```

[Example](./log_spread/advisor.ex)

### Create fill or kill orders

[Example](./fill_or_kill_orders/advisor.ex)

### Cancel pending orders

[Example](./create_and_cancel_pending_order/advisor.ex)
