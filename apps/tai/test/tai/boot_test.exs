defmodule Tai.BootTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event

  @test_id __MODULE__

  @venue_a struct(Tai.Venue, id: :venue_a)
  @venue_b struct(Tai.Venue, id: :venue_b)
  @product_a struct(
               Tai.Venues.Product,
               venue_id: @venue_a.id,
               symbol: :btc_usdt
             )
  @product_b struct(
               Tai.Venues.Product,
               venue_id: @venue_b.id,
               symbol: :btc_usdt
             )
  @config struct(Tai.Config,
            advisor_groups: %{
              log_spread: [
                advisor: Examples.LogSpread.Advisor,
                factory: Tai.Advisors.Factories.OnePerProduct,
                products: "venue_a.btc_usdt venue_b.btc_usdt"
              ]
            }
          )

  defmodule AfterBoot do
    def no_args_hook do
      send(Tai.BootTest, :after_boot_no_args_hook)
    end

    def args_hook(args) do
      send(Tai.BootTest, {:after_boot_args_hook, args})
    end
  end

  defmodule AfterBootError do
    def hook(error) do
      send(Tai.BootTest, {:after_boot_error_args_hook, error})
    end
  end

  setup do
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Venues.ProductStore)
    start_supervised!(Tai.Advisors.SpecStore)
    start_supervised!(Tai.Advisors.Supervisor)
    :ok = Tai.Venues.ProductStore.upsert(@product_a)
    :ok = Tai.Venues.ProductStore.upsert(@product_b)
    :ok
  end

  test ".close_registration/1 checks for venue boot completion" do
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Boot, [id: @test_id, config: @config]})
    refute_event(%Tai.Events.BootAdvisors{}, :info)

    assert Tai.Boot.close_registration(@test_id) == :ok
    assert_event(%Tai.Events.BootAdvisors{} , :info, 1000)
  end

  describe "when all venues successfully start" do
    test "initializes advisor specs" do
      TaiEvents.firehose_subscribe()
      start_supervised!({Tai.Boot, [id: @test_id, config: @config]})

      {:ok, _} = Tai.Boot.register_venue(@venue_a, @test_id)
      {:ok, _} = Tai.Boot.register_venue(@venue_b, @test_id)

      %Tai.Events.VenueStart{venue: @venue_a.id} |> TaiEvents.broadcast(:info)
      refute_event(%Tai.Events.BootAdvisors{}, :info)

      %Tai.Events.VenueStart{venue: @venue_b.id} |> TaiEvents.broadcast(:info)
      assert_event(%Tai.Events.BootAdvisors{} = event, :info, 1000)
      assert event.total == 2
    end

    test "calls the {module, func_name} after_boot hook from config" do
      Process.register(self(), __MODULE__)
      TaiEvents.firehose_subscribe()
      after_boot_config = Map.put(@config, :after_boot, {AfterBoot, :no_args_hook})
      start_supervised!({Tai.Boot, [id: @test_id, config: after_boot_config]})

      {:ok, _} = Tai.Boot.register_venue(@venue_a, @test_id)
      refute_event(%Tai.Events.BootAdvisors{}, :info)

      %Tai.Events.VenueStart{venue: @venue_a.id} |> TaiEvents.broadcast(:info)
      assert_event(%Tai.Events.BootAdvisors{} , :info, 1000)
      assert_receive :after_boot_no_args_hook
    end

    test "calls the {module, func_name, args} after_boot hook from config" do
      Process.register(self(), __MODULE__)
      TaiEvents.firehose_subscribe()

      after_boot_config =
        Map.put(@config, :after_boot, {AfterBoot, :args_hook, arg1: :hello, arg2: :world})

      start_supervised!({Tai.Boot, [id: @test_id, config: after_boot_config]})

      {:ok, _} = Tai.Boot.register_venue(@venue_a, @test_id)
      refute_event(%Tai.Events.BootAdvisors{}, :info)

      %Tai.Events.VenueStart{venue: @venue_a.id} |> TaiEvents.broadcast(:info)
      assert_event(%Tai.Events.BootAdvisors{}, :info, 1000)
      assert_receive {:after_boot_args_hook, arg1: :hello, arg2: :world}
    end
  end

  describe "when any of the venues error on start" do
    test "broadcasts an event" do
      TaiEvents.firehose_subscribe()
      start_supervised!({Tai.Boot, [id: @test_id, config: @config]})

      {:ok, _} = Tai.Boot.register_venue(@venue_a, @test_id)
      {:ok, _} = Tai.Boot.register_venue(@venue_b, @test_id)

      %Tai.Events.VenueStartError{venue: @venue_a.id, reason: [products: :maintenance]}
      |> TaiEvents.broadcast(:error)

      refute_event(%Tai.Events.BootAdvisorsError{}, :error)

      %Tai.Events.VenueStartError{venue: @venue_b.id, reason: [products: :maintenance]}
      |> TaiEvents.broadcast(:error)

      assert_event(%Tai.Events.BootAdvisorsError{} = event, :error, 1000)

      assert event.reason == [
               venue_a: [products: :maintenance],
               venue_b: [products: :maintenance]
             ]
    end

    test "calls the {module, func_name, args} after_boot_error hook from config" do
      Process.register(self(), __MODULE__)
      TaiEvents.firehose_subscribe()
      after_boot_error_config = Map.put(@config, :after_boot_error, {AfterBootError, :hook})

      start_supervised!({Tai.Boot, [id: @test_id, config: after_boot_error_config]})

      {:ok, _} = Tai.Boot.register_venue(@venue_a, @test_id)
      refute_event(%Tai.Events.BootAdvisors{}, :info)

      %Tai.Events.VenueStartError{venue: @venue_a.id, reason: [products: :maintenance]}
      |> TaiEvents.broadcast(:error)

      assert_event(%Tai.Events.BootAdvisorsError{}, :error, 1000)
      assert_receive {:after_boot_error_args_hook, event}
      assert event.reason == [venue_a: [products: :maintenance]]
    end
  end

  test "stops the process when boot is complete" do
    TaiEvents.firehose_subscribe()
    pid = start_supervised!({Tai.Boot, [id: @test_id, config: @config]})
    ref = Process.monitor(pid)

    assert Tai.Boot.close_registration(@test_id) == :ok

    assert_event(%Tai.Events.BootAdvisors{} , :info, 1000)
    assert_receive {:DOWN, ^ref, :process, _object, :normal}
    assert Process.demonitor(ref) == true
    assert Process.alive?(pid) == false
  end
end
