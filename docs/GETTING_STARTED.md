# Getting Started

[Getting Started](./GETTING_STARTED.md) | [Built with Tai](./BUILT_WITH_TAI.md) | [Commands](./COMMANDS.md) | [Architecture](./ARCHITECTURE.md) | [Examples](../apps/examples/README.md) | [Configuration](./CONFIGURATION.md) | [Observability](./OBSERVABILITY.md)

## Install Elixir & Erlang

* We recommend installing [Elixir](https://github.com/asdf-vm/asdf-elixir) & [Erlang](https://github.com/asdf-vm/asdf-erlang) with [asdf](https://github.com/asdf-vm/asdf). A tool to manage the versions of multiple runtimes.

## Learn Elixir & OTP

* [Power of the BEAM Runtime & OTP Distribution - The Soul of Erlang and Elixir](https://www.youtube.com/watch?v=JvBT4XBdoUE) (conference talk video 42 mins)
* Elixir syntax, structure & tools
  * https://www.learnelixir.tv/episodes (video)
  * https://elixirschool.com/en/lessons/basics/basics/ (wiki)
  * https://elixir-lang.org/docs.html (official documentation)
  * [Elixir in Action](https://www.amazon.com/Elixir-Action-Sa%C5%A1a-Juri-cacute/dp/1617295027) (book)
  * [The Little Elixir & OTP Guidebook](https://www.amazon.com/Little-Elixir-OTP-Guidebook-ebook/dp/B0977ZYYXH) (book)
* OTP application architecture best practices
  * [The Do’s and Don’ts of Error Handling](https://www.youtube.com/watch?v=TTM_b7EJg5E) (conference talk video 45 mins)
  * [Designing Elixir Systems With OTP: Write Highly Scalable, Self-healing Software with Layers](https://www.amazon.com/Designing-Elixir-Systems-OTP-Self-healing-ebook/dp/B084NRSQB4) (book)
  * [Concurrent Data Processing in Elixir: Fast, Resilient Applications with OTP, GenStage, Flow, and Broadway](https://www.amazon.com/Concurrent-Data-Processing-Elixir-Applications/dp/1680508199/ref=sr_1_3?dchild=1&keywords=concurrent+data+processing+in+elixir&qid=1626638685&sr=8-3) (book)
* Static analysis & type checking
  * https://elixirschool.com/en/lessons/advanced/typespec/ (wiki)
  * https://elixirschool.com/en/lessons/specifics/debugging/#dialyxir-and-dialyzer (wiki)
  * [Chemanalysis: Dialyzing Elixir](https://www.youtube.com/watch?v=k4au7VioXNk) (conference talk video 38 mins)
  * [Credo](https://github.com/rrrene/credo) (library)
* Testing
  * https://elixirschool.com/en/lessons/basics/testing/ (wiki)
  * https://medium.com/very-big-things/towards-maintainable-elixir-testing-b32ac0604b99 (blog)
  * [Testing Elixir: Effective and Robust Testing for Elixir and its Ecosystem](https://www.amazon.com/Testing-Elixir-Effective-Robust-Ecosystem/dp/1680507826) (book)
  * [Proper](https://github.com/proper-testing/proper) (erlang library for property based testing)
  * [Propcheck](https://github.com/alfert/propcheck) (elixir library for property based testing)
* Fun - [Erlang: The Movie](https://www.youtube.com/watch?v=uKfKtXYLG78) (10 mins)

## Install & Configure Tai

* [https://github.com/fremantle-industries/tai#install](https://github.com/fremantle-industries/tai#install)
* [https://github.com/fremantle-industries/tai/blob/main/docs/CONFIGURATION.md](https://github.com/fremantle-industries/tai/blob/main/docs/CONFIGURATION.md)

## Tai Components & Data Flow

* [https://github.com/fremantle-industries/tai/blob/main/docs/ARCHITECTURE.md#tai-components--data-flow](https://github.com/fremantle-industries/tai/blob/main/docs/ARCHITECTURE.md#tai-components--data-flow)

## Daily Developer Workflow

* Coming soon...

## Mapping Tai to OTP Concepts

* Coming soon...

## Streaming Order Book & Trade Data to Advisors

* [https://github.com/fremantle-industries/tai/tree/main/apps/examples/lib/examples/log_spread](https://github.com/fremantle-industries/tai/tree/main/apps/examples/lib/examples/log_spread)

## Creating and Managing Orders with Advisors

* [https://github.com/fremantle-industries/tai/tree/main/apps/examples/lib/examples/ping_pong](https://github.com/fremantle-industries/tai/tree/main/apps/examples/lib/examples/ping_pong)

## Receiving Custom Data in Advisors

* Coming soon...

## Testing Advisors

* Coming soon...

## Create and Test a New Venue Adapter

* Create or use an [existing Elixir client library](https://github.com/fremantle-industries/ex_ftx) for the venue. This will help with mocks when testing
* Copy the [stub venue adapter](../apps/tai/lib/tai/venue_adapters/stub.ex), [stream supervisor](../apps/tai/lib/tai/venue_adapters/stub/stream_supervisor.ex) and [stream connection](../apps/tai/lib/tai/venue_adapters/stub/stream/connection.ex) for your venue
* Implement the [products](../apps/tai/lib/tai/venue_adapters/stub.ex#L10) callback to fetch the list available on the venue
* Implement the [stream connection](../apps/tai/lib/tai/venue_adapters/stub/stream_supervisor.ex) in the [stream supervisor](../apps/tai/lib/tai/venue_adapters/stub/stream_supervisor.ex) to receive real time order book market data
* Implement the [accounts](../apps/tai/lib/tai/venue_adapters/stub.ex#L16) and [maker/taker fees](../apps/tai/lib/tai/venue_adapters/stub.ex#L19) to retrieve balances stored on the venue
* Implement [positions](../apps/tai/lib/tai/venue_adapters/stub.ex#L22) if the venue supports derivatives
* Implement [create order](../apps/tai/lib/tai/venue_adapters/stub.ex#L25) to place an order on the venue
* Implement [cancel order](../apps/tai/lib/tai/venue_adapters/stub.ex#L28) to cancel a resting order on the venue
* Implement [amend order](../apps/tai/lib/tai/venue_adapters/stub.ex#L31) if the venue supports changing an order in place
* Implement [amend bulk orders](../apps/tai/lib/tai/venue_adapters/stub.ex#L34) if the venue supports changing multiple orders in place
* Configure the new venue for [market data streaming](../config/runtime.exs#L51)
* Configure the [account credentials](../config/runtime.exs#L86) to receive balances and manage orders

## Coordinate Multiple Instances of Tai within an OTP Distribution Cluster

* Coming soon...

## Build an OTP Release and Deploy to the Cloud

* Coming soon...
