# Configuration

[Getting Started](./GETTING_STARTED.md) | [Built with Tai](./BUILT_WITH_TAI.md) | [Commands](./COMMANDS.md) | [Architecture](./ARCHITECTURE.md) | [Examples](../apps/examples/README.md) | [Configuration](./CONFIGURATION.md) | [Observability](./OBSERVABILITY.md)

To quickly get started, take a look at the [example dev configuration](../config/dev.exs.example) for some available options.

## Global

`tai` is configured with standard [Elixir](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html)
constructs under the `:tai` key. Details for each configuration option are provided below:

```elixir
# [default: 10_000] [optional] Adapter start timeout in milliseconds
config :tai, adapter_timeout: 60_000

# [default: nil] [optional] Handler to call after all venues & advisors have successfully started on boot
config :tai, after_boot: {Mod, :func_name, []}

# [default: nil] [optional] Handler to call after any venues or advisors have failed to start on boot
config :tai, after_boot_error: {Mod, :func_name, []}

# [default: false] [optional] Flag which enables the forwarding of each order book change set to the system bus
config :tai, broadcast_change_set: true

# [default: 5] [optional] Maximum pool size
config :tai, order_workers: 5

# [default: 2] [optional] Maximum number of workers created if pool is empty
config :tai, order_workers_max_overflow: 2

# [default: false] [optional] Flag which enables the sending of orders to the venue. When this is `false`, it
# acts a safety net by enqueueing and skipping the order transmission to the venue. This is useful in
# development to prevent accidently sending live orders.
config :tai, send_orders: true

# [default: System.schedulers_online] [optional] Number of processes that can forward internal pubsub messages.
# Defaults to the number of CPU's available in the Erlang VM `System.schedulers_online/0`.
config :tai, system_bus_registry_partitions: 2

# [default: %{}] [optional] Map of configured venues. See below for more details.
config :tai, venues: %{}

# [default: %{}] [optional] Map of configured fleets. See below for more details.
config :tai, fleets: %{}
```

## Venues

`tai` adapters abstract a common interface for interacting with venues. They are configured under
the `:tai, :venues` key.

```elixir
config :tai,
  venues: %{
    okex: [
      # Module that implements the `Tai.Venues.Adapter` behaviour
      adapter: Tai.VenueAdapters.OkEx,

      # [default: %Tai.Config#adapter_timeout] [optional] Per venue override for start
      # timeout in milliseconds
      timeout: 120_000,

      # [default: true] [optional] Starts the venue on initial boot
      start_on_boot: true,

      # [default: []] [optional] Subscribe to venue specific channels
      channels: [],

      # [default: "*"] [optional] A `juice` query matching on alias and symbol, or `{module, func_name}`
      # to filter available products. Juice query syntax is described in more detail at
      # https://github.com/rupurt/juice#usage
      products: "eth_usd_200925 eth_usd_bi_quarter",

      # [default: "*"] [optional] A `juice` query matching on alias and symbol, or `{module, func_name}`
      # to filter streaming order books from available products. Juice query syntax is described in more
      # detail at https://github.com/rupurt/juice#usage
      order_books: "* -eth_usd_200925",

      # [default: 1] [optional] The number of streaming order book levels to maintain. This
      # value has adapter specific support. For example some venues may only allow you to
      # subscribe in blocks of 5 price points. So supported values for that venue
      # are `5`, `10`, `15`, ...
      quote_depth: 1,

      # [default: "*"] [optional] A juice query matching on asset to filter available accounts.
      # Juice query syntax is described in more detail at https://github.com/rupurt/juice#usage
      accounts: "*",

      # [default: %{}] [optional] `Map` of named credentials to use private API's on the venue
      credentials: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      },

      # [default: %{}] [optional] `Map` of extra venue configuration parameters for non-standard
      # tai functionality.
      opts: %{},
    ]
  }
```

## Logging

`tai` uses a system wide event bus and forwards these events to the Elixir
logger. By default Elixir will use the console logger to print logs to `stdout`
in the main process running `tai`. You can configure your Elixir
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
