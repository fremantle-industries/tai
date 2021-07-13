# Observability

[Getting Started](./GETTING_STARTED.md) | [Built with Tai](./BUILT_WITH_TAI.md) | [Install](../README.md#install) | [Usage](../README.md#usage) | [Commands](./COMMANDS.md) | [Architecture](./ARCHITECTURE.md) | [Examples](../apps/examples/README.md) | [Configuration](./CONFIGURATION.md)

Using the [telemetry](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/)
library, `tai` emits metrics that can be used to visualize and alert on the
inner workings of your trading systems.

```elixir
# streams
[:tai, :venues, :stream, :connect]
[:tai, :venues, :stream, :disconnect]
[:tai, :venues, :stream, :terminate]
```
