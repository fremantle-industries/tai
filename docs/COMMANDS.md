# Commands

[Built with Tai](./BUILT_WITH_TAI.md) | [Install](../README.md#install) | [Usage](../README.md#usage) | [Commands](./COMMANDS.md) | [Architecture](./ARCHITECTURE.md) | [Examples](../apps/examples/README.md) | [Configuration](./CONFIGURATION.md)

To monitor your instance, `tai` provides the following set of IEx commands.

## help

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

## accounts

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

## products

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

## fees

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

## markets

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

## orders

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

## venues

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

## stop_venue

Stops the given venue

```
iex(8)> stop_venue :bitmex
stopped successfully
```

## start_venue

Starts the given venue

```
iex(9)> start_venue :bitmex
starting...
```

## settings

Displays the current runtime settings

```
iex(10)> settings
+-------------+-------+
|        Name | Value |
+-------------+-------+
| send_orders | false |
+-------------+-------+
```

## advisors

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

## start_advisors

Starts advisors with an optional filter

```
iex(12)> start_advisors where: [status: :unstarted]
Started advisors: 5 new, 0 already running
```

## stop_advisors

Stops advisors with an optional filter

```
iex(13)> stop_advisors where: [status: :running]
Stopped advisors: 5 new, 0 already stopped
```
