# Tai

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## Log the spread of every order book

```bash
# log/dev.log
2018-10-26T22:31:12.623 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.63936650,6541.11444443,6544.75381093]
2018-10-26T22:31:12.644 [info]  tid=advisor_log_spread_binance_btc_usdt [spread:binance,btc_usdt,0.03,6541.36,6541.39]
2018-10-26T22:31:12.754 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:13.032 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.63936639,6541.11444443,6544.75381082]
2018-10-26T22:31:13.088 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:13.116 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.62303333,6541.11444443,6544.73747776]
2018-10-26T22:31:13.149 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:13.167 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:13.187 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:13.507 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:14.098 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:14.119 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.62303332,6541.11444444,6544.73747776]
2018-10-26T22:31:14.266 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:14.643 [info]  tid=advisor_log_spread_binance_btc_usdt [spread:binance,btc_usdt,0.02,6541.37,6541.39]
2018-10-26T22:31:14.658 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:14.786 [info]  tid=advisor_log_spread_gdax_btc_usd [spread:gdax,btc_usd,0.01,6402.07,6402.08]
2018-10-26T22:31:14.816 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.62303376,6541.114444,6544.73747776]
2018-10-26T22:31:15.123 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.62303375,6541.114444,6544.73747775]
2018-10-26T22:31:15.440 [info]  tid=advisor_log_spread_poloniex_btc_usdt [spread:poloniex,btc_usdt,3.62303353,6541.114444,6544.73747753]
```

[Example](./log_spread/advisor.ex)

## Create fill or kill orders

[Example](./fill_or_kill_orders/advisor.ex)

## Cancel pending orders

[Example](./create_and_cancel_pending_order/advisor.ex)
