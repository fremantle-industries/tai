# Tai
[![Build Status](https://circleci.com/gh/fremantle-capital/tai.png)](https://circleci.com/gh/fremantle-capital/tai)
[![Coverage Status](https://coveralls.io/repos/github/fremantle-capital/tai/badge.svg?branch=master)](https://coveralls.io/github/fremantle-capital/tai?branch=master)

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## WARNING

`tai` is alpha quality software. It passes our test suite but the API is highly 
likely to change and no effort will be made to maintain backwards compatibility at this time.
We are working to make `tai` production quality software.

[Tai on GitHub](https://github.com/fremantle-capital/tai) | [Install](#install) | [Usage](#usage) | [Advisors](#advisors) | [Configuration](#configuration) | [Commands](#commands) | [Logging](#logging)

## What Can I Do? TLDR;

Stream market data, create & manage orders.

Here's an example of an advisor that logs the spread between multiple products on BitMEX

```elixir
# config/config.exs
use Mix.Config

config :tai, send_orders: false

config :tai,
  advisor_groups: %{
    log_spread: [
      advisor: Examples.Advisors.LogSpread.Advisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      products: "*"
    ]
  }

config :tai,
  venues: %{
    bitmex: [
      enabled: true,
      adapter: Tai.VenueAdapters.Bitmex,
      products: "xbtusd ethusd",
      accounts: %{}
    ]
  }

config :echo_boy, port: 4200
```

```
# log/dev.log
09:41:35.950 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"bitmex","spread":"0.01","product_symbol":"xbtusd","bid_price":"5491.05","ask_price":"5491.06"}}
09:41:37.211 [info] {"type":"Examples.Advisors.LogSpread.Events.Spread","data":{"venue_id":"bitmex","spread":"0.05","product_symbol":"ethusd","bid_price":"202.64","ask_price":"202.69"}}
```

## Supported Venues

| Venues | Live Order Book  | Account Balance | Active Orders | Passive Orders | Products | Fees |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|
| Bitmex | [x] | [x] | [x] | [x] | [x] | [x] |

## Venues In Progress

| Venue    | Live Order Book  | Account Balance | Active Orders | Passive Orders | Products | Fees |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|
| Binance  | [x] | [x] | [ ] | [ ] | [x] | [x] |
| OkEx     | [x] | [x] | [ ] | [ ] | [x] | [x] |
| GDAX     | [x] | [x] | [ ] | [ ] | [x] | [x] |
| Poloniex | [x] | [x] | [ ] | [ ] | [x] | [x] |

[Planned Venues...](./PLANNED_VENUES.md)

## Install

`tai` requires Elixir 1.8+ & Erlang/OTP 21+. Add `tai` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [
    {:tai, "~> 0.0.15"}
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

Create an `.iex.exs` file in the root of your project and import the `tai` helper

```elixir
# .iex.exs
Application.put_env(:elixir, :ansi_enabled, true)

import Tai.Commands.Helper
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
* advisor_groups
* advisors
* advisor :group_id, :advisor_id
* settings
* start_advisors
* start_advisor_group :group_id
* start_advisor :group_id, :advisor_id
* stop_advisors
* stop_advisor_group :group_id
* stop_advisor :group_id, :advisor_id
* enable_send_orders
* disable_send_orders
```

#### balance

Display all non-zero balances across configured accounts

```
iex(2)> balance
+-------+---------+--------+------------+------------+------------+
| Venue | Account | Symbol |       Free |     Locked |    Balance |
+-------+---------+--------+------------+------------+------------+
|  gdax |    main |    btc | 0.30000000 | 0.00000000 | 0.30000000 |
|  gdax |    main |    ltc | 1.80009170 | 1.10000000 | 2.90009170 |
|  gdax |    main |    usd |       0.01 |       0.00 |       0.01 |
+-------+---------+--------+------------+------------+------------+
```

#### products

Display the products on the the exchange

```
iex(3)> products
+----------+----------+--------------+---------+-----------+-----------+------------+-----------+-----------------+----------+----------+----------------+--------------+
|    Venue |   Symbol | Venue Symbol |  Status | Maker Fee | Taker Fee |  Min Price | Max Price | Price Increment | Min Size | Max Size | Size Increment | Min Notional |
+----------+----------+--------------+---------+-----------+-----------+------------+-----------+-----------------+----------+----------+----------------+--------------+
|     gdax |  btc_usd |      BTC-USD | trading |           |           |       0.01 |           |            0.01 |    0.001 |       70 |          0.001 |      0.00001 |
|  binance | btc_usdt |      BTCUSDT | trading |           |           |     444.36 |  44435.55 |            0.01 | 0.000001 | 10000000 |       0.000001 |           10 |
| poloniex | btc_usdt |     USDT_BTC | trading |           |           | 0.00000001 |    100000 |                 | 0.000001 |          |       0.000001 |            1 |
|     gdax |  ltc_usd |      LTC-USD | trading |           |           |       0.01 |           |            0.01 |      0.1 |     4000 |            0.1 |        0.001 |
| poloniex | ltc_usdt |     USDT_LTC | trading |           |           | 0.00000001 |    100000 |                 | 0.000001 |          |       0.000001 |            1 |
|  binance | ltc_usdt |      LTCUSDT | trading |           |           |       3.32 |    331.85 |            0.01 |  0.00001 | 10000000 |        0.00001 |           10 |
|   bitmex |   xbth19 |       XBTH19 | trading |   -0.025% |    0.075% |            |   1000000 |             0.5 |        1 | 10000000 |            0.5 |              |
|   bitmex |   xbtz18 |       XBTZ18 | trading |   -0.025% |    0.075% |            |   1000000 |             0.5 |        1 | 10000000 |            0.5 |              |
+----------+----------+--------------+---------+-----------+-----------+------------+-----------+-----------------+----------+----------+----------------+--------------+
```

#### fees

Display the maker/taker fees for the every product in the exchange accounts

```
iex(4)> fees
+---------+------------+-----------+-------+-------+
|   Venue | Account ID |    Symbol | Maker | Taker |
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
from the exchange. This allows you to monitor if a feed is under backpressure and
starting to fall behind as it updates it's order books.

```
iex(5)> markets
+---------+----------+-----------+-----------+------------+--------------+------------------+-----------------------+------------------+-----------------------+
|   Venue |   Symbol | Bid Price | Ask Price |   Bid Size |     Ask Size | Bid Processed At | Bid Server Changed At | Ask Processed At | Ask Server Changed At |
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

Displays the list of orders and their details.

As the lifecycle of the order changes it's details will be updated. You can 
view these changes by running the `orders` command again.

```
iex(6)> orders
+--------+---------+--------+------+-------+--------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
|  Venue | Account | Symbol | Side |  Type |  Price | Avg Price | Qty | Leaves Qty | Cumulative Qty | Time in Force | Status | Client ID | Venue Order ID |    Enqueued At | Last Received At | Last Venue Timestamp |     Updated At | Error Reason |
+--------+---------+--------+------+-------+--------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
| bitmex |    main | xbtm19 |  buy | limit | 3622.5 |         0 |  15 |         15 |              0 |           gtc |   open | 78f616... |      fe7486... | 11 seconds ago |   11 seconds ago |       11 seconds ago | 11 seconds ago |              |
+--------+---------+--------+------+-------+--------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+----------------+------------------+----------------------+----------------+--------------+
```

#### settings

Displays the current runtime settings

```
iex(7)> settings
+-------------+-------+
|        Name | Value |
+-------------+-------+
| send_orders | false |
+-------------+-------+
```

#### advisor_groups

Displays the aggregate status of all advisors in all groups


```
iex(8)> advisor_groups
+---------------------------------+---------+-----------+-------+
|                        Group ID | Running | Unstarted | Total |
+---------------------------------+---------+-----------+-------+
|                      log_spread |       0 |         3 |     3 |
|             fill_or_kill_orders |       0 |         1 |     1 |
| create_and_cancel_pending_order |       0 |         1 |     1 |
+---------------------------------+---------+-----------+-------+
```

#### advisors

Displays every advisor from every group along with their run status 


```
iex(9)> advisors
+---------------------------------+-------------------+-----------+-----+
|                        Group ID |        Advisor ID |    Status | PID |
+---------------------------------+-------------------+-----------+-----+
| create_and_cancel_pending_order |      gdax_btc_usd | unstarted |   - |
|             fill_or_kill_orders |  binance_btc_usdt | unstarted |   - |
|                      log_spread |  binance_btc_usdt | unstarted |   - |
|                      log_spread |      gdax_btc_usd | unstarted |   - |
|                      log_spread | poloniex_btc_usdt | unstarted |   - |
+---------------------------------+-------------------+-----------+-----+
```

#### advisor

Display details of an individual advisor in a group

```
iex(10)> advisor :log_spread, :gdax_btc_usd
Group ID: log_spread
Advisor ID: gdax_btc_usd
Config: %{}
Status: unstarted
PID: -
```

#### start_advisors

Starts every advisor in every group

```
iex(11)> start_advisors
Started advisors: 5 new, 0 already running
```

#### start_advisor_group

Starts every advisor in the given group

```
iex(12)> start_advisor_group :log_spread
Started advisors: 3 new, 0 already running
```

#### start_advisor

Starts a single advisor in given group

```
iex(13)> start_advisor :log_spread, :binance_btc_usdt
Started advisors: 1 new, 0 already running
```

#### stop_advisors

Stops every advisor in every group

```
iex(14)> stop_advisor_groups
Stopped advisors: 5 new, 0 already stopped
```

#### stop_advisor_group

Stops every advisor in the given group

```
iex(15)> start_advisor_group :log_spread
Stopped advisors: 3 new, 0 already stopped
```

#### start_advisor

Stops a single advisor in given group

```
iex(16)> stop_advisor :log_spread, :binance_btc_usdt
Stopped advisors: 1 new, 0 already stopped
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

## Help Wanted :)

If you think this `tai` thing might be worthwhile and you don't see a feature 
or exchange listed we would love your contributions to add them! Feel free to 
drop us an email or open a Github issue.

## Authors

* Alex Kwiatkowski - alex+git@rival-studios.com

## License

`tai` is released under the [MIT license](./LICENSE.md)
