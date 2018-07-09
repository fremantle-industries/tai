# Tai
[![Build Status](https://circleci.com/gh/fremantle-capital/tai.png)](https://circleci.com/gh/fremantle-capital/tai)
[![Coverage Status](https://coveralls.io/repos/github/fremantle-capital/tai/badge.svg?branch=master)](https://coveralls.io/github/fremantle-capital/tai?branch=master)

A trading toolkit built with [Elixir](https://elixir-lang.org/) that runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

## WARNING

`tai` is alpha quality software. It passes our test suite but the API is highly 
likely to change and no effort will be made to maintain backwards compatibility at this time.
We are working to make `tai` production quality software.

[Tai on GitHub](https://github.com/fremantle-capital/tai) | [Install](#install) | [Usage](#usage) | [Advisors](#advisors) | [Configuration](#configuration) | [Debugging](#debugging)


## Supported Exchanges

| Exchange       | Live Order Book  | Account Balance | Orders |
|----------------|:---:|:---:|:---:|
| GDAX           | [x] | [x] | [x] |
| Binance        | [x] | [x] | [x] |
| Poloniex       | [x] | [x] | [x] |

## Planned Exchanges

| Exchange       | Live Order Book  | Orders |
|----------------|:----:|:--------------:|
| Bitfinex           | [ ] | [ ] |
| Bitflyer           | [ ] | [ ] |
| Bithumb            | [ ] | [ ] |
| Bitmex             | [ ] | [ ] |
| Bitstamp           | [ ] | [ ] |
| Bittrex            | [ ] | [ ] |
| Gemini             | [ ] | [ ] |
| HitBtc             | [ ] | [ ] |
| Huobi              | [ ] | [ ] |
| Kraken             | [ ] | [ ] |
| OkCoin             | [ ] | [ ] |
| ...                | [ ] | [ ] |

[Full List...](./PLANNED_EXCHANGES.md)

## Install

Tai requires Elixir 1.6. Add `tai` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [
    {:tai, "~> 0.0.3"}
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
a shortname so that we can connect and observe the node at any time via iex:

```bash
iex --sname client --remsh tai@localhost
```

This gives you an interactive elixir shell with a set of tai helper commands:

### Commands

You can view your [total balance](#balance), inspect the [state of orders](#orders), 
display [live markets](#markets) or execute manual orders using the following commands.

#### help

Display the available commands and usage examples

```bash
iex(1)> help
* balance
* markets
* orders
* buy_limit account_id(:gdax), symbol(:btc_usd), price(101.12), size(1.2)
* sell_limit account_id(:gdax), symbol(:btc_usd), price(101.12), size(1.2)
* order_status account_id(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
* cancel_order account_id(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
```

#### balance

Display all non-zero balances across configured accounts


```
iex(2)> balance
+---------+--------+-------------+
| Account | Symbol |     Balance |
+---------+--------+-------------+
|    gdax |    btc |  1.00000720 |
|    gdax |    ltc | 18.00200141 |
|    gdax |    usd |        0.01 |
+---------+--------+-------------+
```

#### markets

Displays the live top of the order book for the configured feeds. It includes 
the time they were processed locally and if supported, the time they were sent 
from the exchange. This allows you to monitor if a feed is under backpressure and
starting to fall behind as it updates it's order books.

```
iex(3)> markets
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
iex(4)> orders
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
| Account |  Symbol |      Type | Price | Size | Status |                            Client ID | Server ID |    Enqueued At | Created At |
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
|    gdax | btc_usd | buy_limit | 100.1 |  0.1 |  error | a6aa15bc-b271-486f-ab40-f9b35b2cd223 |           | 20 minutes ago |            |
+---------+---------+-----------+-------+------+--------+--------------------------------------+-----------+----------------+------------+
```

## Advisors

Advisors are the brains of any `tai` application, they receive events such 
as order book changes or trades and can create, edit or cancel orders. They 
are intended to run without supervision to analyze and record data or execute 
trading strategies.

Take a look at some of the [examples](./examples/advisors) to understand how to create advisors.

## Configuration

Each environment can have its own configuration. Take a look at the [example dev configuration](config/dev.exs.example) 
for available options.

## Debugging

`tai` keeps detailed logs of it's operations while running. They are written to a file with the name of the environment e.g. `logs/dev.log`. By default only `info`, `warn` & `error` messages are logged. If you would like to enable verbose logging that is useful for development and debugging you can set the `DEBUG` environment variable before you run tai.

```bash
DEBUG=true iex -S mix
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

## Authors

* Alex Kwiatkowski - alex+git@rival-studios.com

## License

`tai` is released under the [MIT license](./LICENSE.md)
