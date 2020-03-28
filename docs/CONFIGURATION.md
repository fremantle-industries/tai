# Configuration

[Built with Tai](./BUILT_WITH_TAI.md) | [Install](../README.md#install) | [Usage](../README.md#usage) | [Commands](./COMMANDS.md) | [Architecture](./ARCHITECTURE.md) | [Configuration](./CONFIGURATION.md)

To quickly get started, take a look at the [example dev configuration](../config/dev.exs.example) for some available options.

## Clustering

Welcome to the wild world of distributed computing! Elixir/Erlang provide first class support for 
running your application within a multi node cluster and `tai` provides a uniform interface to interact
with instances across your cluster.

Let's get started by running the examples from this repository as 2 separate local nodes. We'll call 
them `a` & `b`, and they'll be configured with the [example dev cluster configuration](../config/dev.exs.cluster.example).

```
$ iex --sname a -S mix
```
```
$ iex --sname b -S mix
```

First off we'll inspect venues running on each instance.

```
iex(a@macbook)1> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | running |        - |           1 |   10000 |          true |
|    gdax |           - | running |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
```
```
iex(b@macbook)1> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | running |        - |           1 |   10000 |          true |
|    gdax |           - | running |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
```

You'll notice that they both have 2 venues running, `binance` & `gdax`. Let's stop `binance` on node `a`, 
and inspect the venues on both nodes again.

```
iex(a@macbook)2> stop_venue :binance
stopped successfully
iex(a@macbook)3> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | stopped |        - |           1 |   10000 |          true |
|    gdax |           - | running |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
```
```
iex(b@macbook)2> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | running |        - |           1 |   10000 |          true |
|    gdax |           - | running |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
```

These `IEx` commands are powered by the [`Tai.Commander`](../apps/tai/lib/tai/commander.ex) `GenServer` process 
behind the scenes. Let's inspect the venues again, this time using `Tai.Commander`.

```
iex(a@macbook)4> Tai.Commander.venues()
[
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Binance,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :binance,
    opts: %{},
    products: "btc_usdt ltc_usdt eth_usdt",
    quote_depth: 1,
    start_on_boot: true,
    status: :stopped,
    timeout: 10000
  },
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Gdax,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :gdax,
    opts: %{},
    products: "btc_usd ltc_usd eth_usd",
    quote_depth: 1,
    start_on_boot: true,
    status: :running,
    timeout: 10000
  }
]
```
```
iex(b@macbook)3> Tai.Commander.venues()
[
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Binance,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :binance,
    opts: %{},
    products: "btc_usdt ltc_usdt eth_usdt",
    quote_depth: 1,
    start_on_boot: true,
    status: :running,
    timeout: 10000
  },
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Gdax,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :gdax,
    opts: %{},
    products: "btc_usd ltc_usd eth_usd",
    quote_depth: 1,
    start_on_boot: true,
    status: :running,
    timeout: 10000
  }
]
```

This command returns Elixir structs representing an instance of a venue. You'll notice that the status 
of the `binance` instance on node `a` is `:stopped`.

Let's issue that command again on node `a`, this time passing in node `b`

```
iex(a@macbook)5> Tai.Commander.venues(node: :"b@macbook")
[
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Binance,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :binance,
    opts: %{},
    products: "btc_usdt ltc_usdt eth_usdt",
    quote_depth: 1,
    start_on_boot: true,
    status: :running,
    timeout: 10000
  },
  %Tai.Venues.Instance{
    accounts: "*",
    adapter: Tai.VenueAdapters.Gdax,
    broadcast_change_set: false,
    channels: [],
    credentials: %{},
    id: :gdax,
    opts: %{},
    products: "btc_usd ltc_usd eth_usd",
    quote_depth: 1,
    start_on_boot: true,
    status: :running,
    timeout: 10000
  }
]
```

These are the instances of venues running on node `b`. You'll notice that `binance` is still `:running` on node `b`!

This `node: :nodename` option can be provided on all `Tai.Commander` commands to inspect and control nodes 
running `tai` across your cluster. With your newly acquired super power, let's decommission node `a` and stop it's 
last remaining venue.

```
iex(b@macbook)4> Tai.Commander.stop_venue(:gdax, node: :"a@macbook")
:ok
```
```
iex(a@macbook)6> venues
+---------+-------------+---------+----------+-------------+---------+---------------+
|      ID | Credentials |  Status | Channels | Quote Depth | Timeout | Start On Boot |
+---------+-------------+---------+----------+-------------+---------+---------------+
| binance |           - | stopped |        - |           1 |   10000 |          true |
|    gdax |           - | stopped |        - |           1 |   10000 |          true |
+---------+-------------+---------+----------+-------------+---------+---------------+
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

Take a look at our example [dev configuration](../config/dev.exs.example#L32) which 
reads secrets from the file system.
