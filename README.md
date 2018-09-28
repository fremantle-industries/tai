# Tai
[![Build Status](https://circleci.com/gh/fremantle-capital/tai.png)](https://circleci.com/gh/fremantle-capital/tai)
[![Coverage Status](https://coveralls.io/repos/github/fremantle-capital/tai/badge.svg?branch=master)](https://coveralls.io/github/fremantle-capital/tai?branch=master)

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## WARNING

`tai` is alpha quality software. It passes our test suite but the API is highly 
likely to change and no effort will be made to maintain backwards compatibility at this time.
We are working to make `tai` production quality software.

[Tai on GitHub](https://github.com/fremantle-capital/tai) | [Install](#install) | [Usage](#usage) | [Advisors](#advisors) | [Configuration](#configuration) | [Commands](#commands) | [Debugging](#debugging)


## Supported Exchanges

| Exchange       | Live Order Book  | Account Balance | Orders | Products | Fees |
|----------------|:---:|:---:|:---:|:---:|:---:|
| GDAX           | [x] | [x] | [x] | [x] | [x] |
| Binance        | [x] | [x] | [x] | [x] | [x] |
| Poloniex       | [x] | [x] | [x] | [x] | [x] |

## Planned Exchanges

| Exchange       |
|----------------|
| Bitfinex       |
| Bitflyer       |
| Bithumb        |
| Bitmex         |
| Bitstamp       |
| Bittrex        |
| Gemini         |
| HitBtc         |
| Huobi          |
| Kraken         |
| OkCoin         |
| ...            |

[Full List...](./PLANNED_EXCHANGES.md)

## Install

`tai` requires Elixir 1.7+ & Erlang/OTP 21+. Add `tai` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [
    {:tai, "~> 0.0.5"}
  ]
end
```

Or use the lastest from `master`

```elixir
def deps do
  [
    {:tai, github: "fremantle-capital/tai"}
  ]
end
```

## Usage

`tai` runs as an OTP application.

During development we can leverage `mix` to compile and run our application:

```bash
elixir --sname tai -S mix run --no-halt
```

This will run your `tai` configuration as a process in the foreground. We assign
a shortname so that we can connect and observe the node at any time via `iex`:

```bash
iex --sname client --remsh tai@mymachinename
```

This gives you an interactive elixir shell with a set of `tai` helper [commands](#commands)

## Advisors

Advisors are the brains of any `tai` application, they subscribe to changes in
order books and process these events to record and analyze data or execute
automated trading strategies.

Orders can be created and managed through a uniform API across exchanges, with 
fast execution and reliability.

Take a look at some of the [examples](./examples/advisors) to understand what 
you can create with advisors in just a few lines of code.

## Configuration

Each environment can have its own configuration. Take a look at the [example dev configuration](config/dev.exs.example) 
for available options.

## Commands

You can monitor your [account balances](#balance), list the tradeable 
[products](#products) and their [fees](#fees), view [live markets](#markets) 
and inspect the [state of orders](#orders).

#### help

Display the available commands and usage examples

```bash
iex(1)> help
* balance
* products
* fees
* markets
* orders
* settings
* enable_send_orders
* disable_send_orders
```

#### balance

Display all non-zero balances across configured accounts

```
iex(2)> balance
+----------+---------+--------+------------+------------+------------+
| Exchange | Account | Symbol |       Free |     Locked |    Balance |
+----------+---------+--------+------------+------------+------------+
|     gdax |    main |    btc | 0.30000000 | 0.00000000 | 0.30000000 |
|     gdax |    main |    ltc | 1.80009170 | 1.10000000 | 2.90009170 |
|     gdax |    main |    usd |       0.01 |       0.00 |       0.01 |
+----------+---------+--------+------------+------------+------------+
```

#### products

Display the products on the the exchange

```
iex(3)> products
+-------------+-----------+-----------------+---------+--------------+----------------+-----------------+------------+-------------------+----------------+--------------+
| Exchange ID |    Symbol | Exchange Symbol |  Status |    Min Price |      Max Price | Price Increment |   Min Size |          Max Size | Size Increment | Min Notional |
+-------------+-----------+-----------------+---------+--------------+----------------+-----------------+------------+-------------------+----------------+--------------+
|     binance |   ada_bnb |          ADABNB | trading |   0.00141000 |     0.14090000 |      0.00001000 | 0.01000000 | 90000000.00000000 |     0.01000000 |   1.00000000 |
|     binance |   ada_btc |          ADABTC | trading |   0.00000248 |     0.00024710 |      0.00000001 | 1.00000000 | 90000000.00000000 |     1.00000000 |   0.00100000 |
|     binance |   ada_eth |          ADAETH | trading |   0.00003799 |     0.00379850 |      0.00000001 | 1.00000000 | 90000000.00000000 |     1.00000000 |   0.01000000 |
|     binance |  ada_usdt |         ADAUSDT | trading |   0.01814000 |     1.81375000 |      0.00001000 | 0.10000000 | 90000000.00000000 |     0.10000000 |  10.00000000 |
|     binance |   adx_bnb |          ADXBNB | trading |   0.00326000 |     0.32570000 |      0.00001000 | 0.01000000 | 90000000.00000000 |     0.01000000 |   1.00000000 |
|     binance |   adx_btc |          ADXBTC | trading |   0.00000572 |     0.00057130 |       0.0000001 | 1.00000000 | 90000000.00000000 |     1.00000000 |   0.00100000 |
|     binance |   adx_eth |          ADXETH | trading |   0.00008840 |     0.00883600 |       0.0000001 | 1.00000000 | 90000000.00000000 |     1.00000000 |   0.01000000 |
|     binance |    ae_bnb |           AEBNB | trading |   0.01500000 |     1.50000000 |      0.00001000 | 0.01000000 | 90000000.00000000 |     0.01000000 |   1.00000000 |
|     binance |    ae_btc |           AEBTC | trading |   0.00002640 |     0.00263400 |       0.0000001 | 0.01000000 | 90000000.00000000 |     0.01000000 |   0.00100000 |
+-------------+-----------+-----------------+---------+--------------+----------------+-----------------+------------+-------------------+----------------+--------------+
```

#### fees

Display the maker/taker fees for the every product in the exchange accounts

```
iex(4)> fees
+-------------+------------+-----------+-------+-------+
| Exchange ID | Account ID |    Symbol | Maker | Taker |
+-------------+------------+-----------+-------+-------+
|     binance |       main |   lsk_bnb |  0.1% |  0.1% |
|     binance |       main |   rlc_eth |  0.1% |  0.1% |
|     binance |       main |  aion_eth |  0.1% |  0.1% |
|     binance |       main |   mft_bnb |  0.1% |  0.1% |
|     binance |       main |  ardr_bnb |  0.1% |  0.1% |
|     binance |       main |  iost_btc |  0.1% |  0.1% |
|     binance |       main |   xlm_eth |  0.1% |  0.1% |
|     binance |       main |   xem_eth |  0.1% |  0.1% |
|     binance |       main |   kmd_btc |  0.1% |  0.1% |
|     binance |       main | ncash_btc |  0.1% |  0.1% |
|     binance |       main |   xrp_eth |  0.1% |  0.1% |
|     binance |       main |   vet_bnb |  0.1% |  0.1% |
+-------------+------------+-----------+-------+-------+
```

#### markets

Displays the live top of the order book for the configured feeds. It includes 
the time they were processed locally and if supported, the time they were sent 
from the exchange. This allows you to monitor if a feed is under backpressure and
starting to fall behind as it updates it's order books.

```
iex(5)> markets
+---------+----------+-----------+-----------+------------+--------------+------------------+-----------------------+------------------+-----------------------+
|    Feed |   Symbol | Bid Price | Ask Price |   Bid Size |     Ask Size | Bid Processed At | Bid Server Changed At | Ask Processed At | Ask Server Changed At |
+---------+----------+-----------+-----------+------------+--------------+------------------+-----------------------+------------------+-----------------------+
| binance | btc_usdt |    8430.0 |   8439.91 |   0.349355 |     1.021896 |     1 second ago |          1 second ago |              now |                   now |
| binance | ltc_usdt |    159.53 |    159.58 |   10.54534 |      1.02855 |    9 seconds ago |         9 seconds ago |    4 seconds ago |         4 seconds ago |
| binance | eth_usdt |    519.67 |     520.0 |    0.08984 |      2.33198 |    7 seconds ago |         7 seconds ago |              now |                   now |
|    gdax |  btc_usd |   8430.86 |   8430.87 | 0.01448655 |  24.32791169 |    3 seconds ago |         3 seconds ago |     1 second ago |          1 second ago |
|    gdax |  ltc_usd |    159.97 |    159.98 |    0.00002 | 478.22565196 |   28 seconds ago |        28 seconds ago |              now |                   now |
|    gdax |  eth_usd |    520.93 |    520.94 | 9.48431449 |  79.37008001 |              now |                   now |     1 second ago |         2 seconds ago |
+---------+----------+-----------+-----------+------------+--------------+------------------+-----------------------+------------------+-----------------------+
```

#### orders

Displays the list of orders and their status.

**[IN PROGRESS:](https://github.com/fremantle-capital/tai/tree/order-feed-spike)**

As the lifecycle of the order changes i.e. partial fills, process events and 
update in the background so that the information is available when you re-run 
the `orders` command.

```
iex(6)> orders
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
| Account |  Symbol |      Type | Price | Size | Status |                            Client ID | Server ID |    Enqueued At | Created At |
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
|    gdax | btc_usd | buy_limit | 100.1 |  0.1 |  error | a6aa15bc-b271-486f-ab40-f9b35b2cd223 |           | 20 minutes ago |            |
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
```

## Debugging

`tai` keeps detailed logs of it's operations while running. They are written to a file with the name of the environment e.g. `logs/dev.log`. By default only `info`, `warn` & `error` messages are logged. If you would like to enable verbose logging that is useful for development and debugging you can set the `DEBUG` environment variable before you run tai.

```bash
DEBUG=true iex --sname client --remsh tai@mymachinename
```

To monitor a running instance of `tai` you can `tail` it's log

```bash
tail -f logs/dev.log
```

You can combine `tail` with `grep` to filter the logs for specific components or patterns. 

e.g. Filter log messages created by the `CreateAndCancelPendingOrder` advisor

```bash
tail -f logs/dev.log | grep advisor_create_and_cancel_pending_order
```

## Help Wanted :)

If you think this `tai` thing might be worthwhile and you don't see a feature 
or exchange listed we would love your contributions to add them! Feel free to 
drop us an email or open a Github issue.

## Authors

* Alex Kwiatkowski - alex+git@rival-studios.com

## License

`tai` is released under the [MIT license](./LICENSE.md)
