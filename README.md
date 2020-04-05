# Tai
[![Build Status](https://github.com/fremantle-capital/tai/workflows/Test/badge.svg?branch=master)](https://github.com/fremantle-capital/tai/actions?query=workflow%3ATest)
[![Coverage Status](https://coveralls.io/repos/github/fremantle-capital/tai/badge.svg?branch=master)](https://coveralls.io/github/fremantle-capital/tai?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/tai.svg?style=flat)](https://hex.pm/packages/tai)

A composable, real time, market data and trade execution toolkit. Built with [Elixir](https://elixir-lang.org/), runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

[Built with Tai](./docs/BUILT_WITH_TAI.md) | [Install](#install) | [Usage](#usage) | [Advisors](#advisors) | [Configuration](#configuration) | [Commands](#commands) | [Logging](#logging)

## What Can I Do? TLDR;

Stream market data to create and manage orders with a near-uniform API across multiple venues

Here's an example of an advisor that logs the spread between multiple products on multiple venues

[![asciicast](https://asciinema.org/a/259561.svg)](https://asciinema.org/a/259561)

## Supported Venues

| Venues | Live Order Book  | Accounts | Active Orders | Passive Orders | Products | Fees |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|
| BitMEX | [x] | [x] | [x] | [x] | [x] | [x] |
| OkEx   | [x] | [x] | [x] | [x] | [x] | [x] |

## Venues In Progress

| Venue    | Live Order Book  | Accounts | Active Orders | Passive Orders | Products | Fees |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|
| Binance  | [x] | [x] | [x] | [ ] | [x] | [x] |
| Deribit  | [x] | [x] | [ ] | [ ] | [x] | [x] |
| GDAX     | [x] | [x] | [ ] | [ ] | [x] | [x] |
| Huobi    | [x] | [ ] | [ ] | [ ] | [x] | [ ] |
| FTX      | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Coinflex | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Bybit    | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| bitFlyer | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Kraken   | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Bitfinex | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

## Install

`tai` requires Elixir 1.8+ & Erlang/OTP 21+. Add `tai` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [{:tai, "~> 0.0.53"}]
end
```

Create an `.iex.exs` file in the root of your project and import the `tai` helper

```elixir
# .iex.exs
Application.put_env(:elixir, :ansi_enabled, true)

import Tai.IEx
```

## Usage

`tai` runs as an OTP application.

During development we can leverage `mix` to compile and run our application with an 
interactive Elixir shell that imports the set of `tai` helper [commands](#commands).

```bash
iex -S mix
```

## Advisors

Advisors are the brains of any `tai` application, they subscribe to changes in
market data to record and analyze data or execute automated trading strategies.

Orders are created and managed through a uniform API across exchanges, with 
fast execution and reliability.

Take a look at some of the [examples](./apps/examples) to understand what 
you can create with advisors.

## Configuration

Each environment can have its own configuration. Take a look at the [example dev configuration](config/dev.exs.example) 
for available options.

## Commands

To monitor your advisors, accounts and markets `tai` provides the following set of IEx commands.

#### help

Display the available commands and usage examples

```bash
iex(1)> help
* accounts
* products
* fees
* markets
* orders
* venues [where: [...], order: [...]]
* start_venue :venue_id
* stop_venue :venue_id
* advisors [where: [...], order: [...]]
* start_advisors [where: [...]]
* stop_advisors [where: [...]]
* settings
* enable_send_orders
* disable_send_orders
```

#### accounts

Display the configured accounts with non-zero balances

```
iex(2)> accounts
+-------+------------+--------+------------+------------+------------+
| Venue | Credential | Symbol |       Free |     Locked |    Balance |
+-------+------------+--------+------------+------------+------------+
|  gdax |       main |    btc | 0.30000000 | 0.00000000 | 0.30000000 |
|  gdax |       main |    ltc | 1.80009170 | 1.10000000 | 2.90009170 |
|  gdax |       main |    usd |       0.01 |       0.00 |       0.01 |
+-------+------------+--------+------------+------------+------------+
```

#### products

Display the products provided by configured venues

```
iex(3)> products
+---------+----------+--------------+---------+--------+-----------+-----------+
|   Venue |   Symbol | Venue Symbol |  Status |   Type | Maker Fee | Taker Fee |
+---------+----------+--------------+---------+--------+-----------+-----------+ 
|    gdax |  btc_usd |      BTC-USD | trading |   spot |           |           |
| binance | btc_usdt |      BTCUSDT | trading |   spot |           |           |
|    gdax |  eth_usd |      ETH-USD | trading |   spot |           |           | 
| binance | eth_usdt |      ETHUSDT | trading |   spot |           |           |
|    gdax |  ltc_usd |      LTC-USD | trading |   spot |           |           |
| binance | ltc_usdt |      LTCUSDT | trading |   spot |           |           | 
|  bitmex |   xbtusd |       XBTUSD | trading | future |   -0.025% |    0.075% |
+---------+----------+--------------+---------+--------+-----------+-----------+
```

#### fees

Display the maker/taker fees for every product from configured venue accounts

```
iex(4)> fees
+---------+------------+-----------+-------+-------+
|   Venue | Credential |    Symbol | Maker | Taker |
+---------+------------+-----------+-------+-------+
| binance |       main |   lsk_bnb |  0.1% |  0.1% |
| binance |       main |   rlc_eth |  0.1% |  0.1% |
| binance |       main |  aion_eth |  0.1% |  0.1% |
| binance |       main |   mft_bnb |  0.1% |  0.1% |
| binance |       main |  ardr_bnb |  0.1% |  0.1% |
| binance |       main |  iost_btc |  0.1% |  0.1% |
| binance |       main |   xlm_eth |  0.1% |  0.1% |
| binance |       main |   xem_eth |  0.1% |  0.1% |
| binance |       main |   kmd_btc |  0.1% |  0.1% |
| binance |       main | ncash_btc |  0.1% |  0.1% |
| binance |       main |   xrp_eth |  0.1% |  0.1% |
| binance |       main |   vet_bnb |  0.1% |  0.1% |
+---------+------------+-----------+-------+-------+
```

#### markets

Displays the live top of the order book for the configured feeds. It includes 
the time they were processed locally and if supported, the time they were sent 
from the venue. This allows you to monitor if a feed is under backpressure and
starting to fall behind as it updates it's order books.

```
iex(5)> markets
+---------+----------+-----------+-----------+------------+--------------+
|   Venue |   Symbol | Bid Price | Ask Price |   Bid Size |     Ask Size |
+---------+----------+-----------+-----------+------------+--------------+
| binance | btc_usdt |    8430.0 |   8439.91 |   0.349355 |     1.021896 |
| binance | ltc_usdt |    159.53 |    159.58 |   10.54534 |      1.02855 |
| binance | eth_usdt |    519.67 |     520.0 |    0.08984 |      2.33198 |
|    gdax |  btc_usd |   8430.86 |   8430.87 | 0.01448655 |  24.32791169 |
|    gdax |  ltc_usd |    159.97 |    159.98 |    0.00002 | 478.22565196 |
|    gdax |  eth_usd |    520.93 |    520.94 | 9.48431449 |  79.37008001 |
+---------+----------+-----------+-----------+------------+--------------+
```

#### orders

Displays the list of orders and their details.

As the lifecycle of the order changes it's details will be updated. You can 
view these changes by running the `orders` command again.

```
iex(6)> orders
+--------+------------+--------+------+-------+--------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
|  Venue | Credential | Symbol | Side |  Type |  Price | Qty | Leaves Qty | Cumulative Qty | Time in Force | Status | Client ID | Venue Order ID |    Enqueued At | Last Received At | Last Venue Timestamp |     Updated At | Error Reason |
+--------+------------+--------+------+-------+--------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
| bitmex |       main | xbtusd |  buy | limit | 3622.5 |  15 |         15 |              0 |           gtc |   open | 78f616... |      fe7486... | 11 seconds ago |   11 seconds ago |       11 seconds ago | 11 seconds ago |              |
+--------+------------+--------+------+-------+--------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
```

#### venues

List venues that can optionally be filtered and ordered

```
iex(7)> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | running |        - |           1 |   10000 |          true |
|  bitmex |           - | running |        - |           3 |   10000 |          true |
|    gdax |           - | running |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
```

### stop_venue

Stops the given venue

```
iex(8)> stop_venue :bitmex
stopped successfully
```

### start_venue

Starts the given venue

```
iex(9)> start_venue :bitmex
starting...
```

#### settings

Displays the current runtime settings

```
iex(10)> settings
+-------------+-------+
|        Name | Value |
+-------------+-------+
| send_orders | false |
+-------------+-------+
```

#### advisors

List advisors that can optionally be filtered and ordered


```
iex(11)> advisors where: [status: :unstarted], order: [:group_id]
+---------------------------------+-------------------+-----------+-----+
|                        Group ID |        Advisor ID |    Status | PID |
+---------------------------------+-------------------+-----------+-----+
| create_and_cancel_pending_order |      gdax_btc_usd | unstarted |   - |
|             fill_or_kill_orders |  binance_btc_usdt | unstarted |   - |
|                      log_spread |  binance_btc_usdt | unstarted |   - |
|                      log_spread |      gdax_btc_usd | unstarted |   - |
|                      log_spread |     bitmex_xbtusd | unstarted |   - |
+---------------------------------+-------------------+-----------+-----+
```

#### start_advisors

Starts advisors with an optional filter

```
iex(12)> start_advisors where: [status: :unstarted]
Started advisors: 5 new, 0 already running
```

#### stop_advisors

Stops advisors with an optional filter

```
iex(13)> stop_advisors where: [status: :running]
Stopped advisors: 5 new, 0 already stopped
```

## Logging

`tai` uses a system wide event bus and forwards these events to the Elixir 
logger. By default Elixir will use the console logger to print logs to `stdout` 
in the main process running `tai`.  You can configure your Elixir 
logger to format or change the location of the output.

For example. To write to a file, add a file logger:

```elixir
# mix.exs
defp deps do
  {:logger_file_backend, "~> 0.0.10"}
end
```

And configure it's log location:

```elixir
# config/config.exs
use Mix.Config

config :logger, :file_log, path: "./log/#{Mix.env()}.log"
config :logger, backends: [{LoggerFileBackend, :file_log}]
```

If you intend to deploy `tai` to a service that ingests structured logs, you 
will need to use a supported backed. For Google Cloud Stackdriver you can use `logger_json`

```elixir
# mix.exs
defp deps do
  {:logger_json, "~> 2.0.1"}
end

# config/config.exs
use Mix.Config

config :logger_json, :backend, metadata: :all
config :logger, backends: [LoggerJSON]
```

## Secrets

Managing secrets is a complex and opinionated topic. We recommend that you avoid compiling 
application secrets into your OTP release and regularly rotate them. This can be achieved in many 
different ways, `tai` has chosen to use [confex](https://github.com/Nebo15/confex) to manage 
this workflow. `confex` provides the ability to read secrets from environment variables or the 
file system out of the box. It also has the ability to read secrets from any location you 
wish via a custom adapter.

Take a look at our example [dev configuration](./config/dev.exs.example#L32) which 
reads secrets from the file system.

## Help Wanted :)

If you think this `tai` thing might be worthwhile and you don't see a feature 
or venue listed we would love your contributions to add them! Feel free to 
drop us an email or open a Github issue.

## Authors

* Alex Kwiatkowski - alex+git@fremantle.io

## License

`tai` is released under the [MIT license](./LICENSE.md)
