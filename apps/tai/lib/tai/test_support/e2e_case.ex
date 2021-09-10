defmodule Tai.TestSupport.E2ECase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Tai.Orders.OrderRepo
      alias Tai.TestSupport.Mocks

      import ExUnit.CaptureIO
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Tai.TestSupport.DataCase
      import Tai.TestSupport.Mock
      import Tai.TestSupport.Assertions.Event
      import Tai.TestSupport.Factories.OrderSubmissionFactory
      import Tai.TestSupport.Factories.OrderFactory
      import Tai.TestSupport.Factories.OrderTransitionFactory
      import Tai.TestSupport.Factories.FailedOrderTransitionFactory

      setup do
        stop_app()
        start_mock_server()
        before_start_app()
        start_app()
        after_start_app()

        receive do
          {TaiEvents.Event, %Tai.Events.BootAdvisors{}, :info} ->
            after_boot_app()

          {TaiEvents.Event, %Tai.Events.BootAdvisorsError{} = event, :error} ->
            after_boot_app_error(event)
        after
          5000 -> flunk("Time out waiting 5000ms for tai to boot")
        end

        :ok
      end

      def start_mock_server do
        start_supervised!(Tai.TestSupport.Mocks.Server)
      end

      def start_app do
        {:ok, _} = Application.ensure_all_started(:echo_boy)
        {:ok, _} = Application.ensure_all_started(:tai_events)
        TaiEvents.firehose_subscribe()
        {:ok, _} = Application.ensure_all_started(:tai)
        Phoenix.PubSub.subscribe(Tai.PubSub, "order_updated:*")

        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Tai.Orders.OrderRepo)
        Ecto.Adapters.SQL.Sandbox.mode(Tai.Orders.OrderRepo, {:shared, self()})

        {:ok, _} = e2e_app() |> Application.ensure_all_started()
        Tai.Settings.enable_send_orders!()
      end

      def stop_app do
        Application.stop(:tai)
        e2e_app() |> Application.stop()
      end

      def seed_mock_responses(scenario_name) do
        scenario = fetch_mod!(scenario_name)
        scenario.seed_mock_responses(scenario_name)
      end

      def seed_venues(scenario_name) do
        scenario = fetch_mod!(scenario_name)
        scenario.seed_venues(scenario_name)
      end

      def push_stream_market_data({scenario_name, _, _, _} = args) do
        scenario = fetch_mod!(scenario_name)
        scenario.push_stream_market_data(args)
      end

      def push_stream_order_update({scenario_name, _, _, _} = scenario_args, client_id) do
        scenario = fetch_mod!(scenario_name)
        scenario.push_stream_order_update(scenario_args, client_id)
      end

      def configure_fleet(scenario_name) do
        scenario = fetch_mod!(scenario_name)
        scenario_fleet_config = scenario.fleet_config(scenario_name)
        fleet_configs = Map.put(%{}, scenario_name, scenario_fleet_config)
        Tai.Fleets.load(fleet_configs)
      end

      def start_advisors(args) do
        capture_io(fn -> Tai.IEx.start_advisors(args) end)
      end

      def stop_advisors(args) do
        capture_io(fn -> Tai.IEx.stop_advisors(args) end)
      end

      def start_venue(venue_id) do
        capture_io(fn -> Tai.IEx.start_venue(venue_id) end)

        receive do
          {TaiEvents.Event, %Tai.Events.VenueStart{}, :info} ->
            nil

          {TaiEvents.Event, %Tai.Events.VenueStartError{} = event, :error} ->
            flunk("Error starting venue: #{inspect(event.reason)}")
        after
          5000 -> flunk("Time out waiting 5000ms for venue to start")
        end
      end

      defp e2e_app, do: Application.fetch_env!(:tai, :e2e_app)

      defp fetch_mod!(scenario_name) do
        e2e_app()
        |> Application.get_env(:e2e_mappings, %{})
        |> Map.fetch!(scenario_name)
      end

      @spec before_start_app :: no_return
      def before_start_app, do: nil

      @spec after_start_app :: no_return
      def after_start_app, do: nil

      @spec after_boot_app :: no_return
      def after_boot_app, do: nil

      @spec after_boot_app_error(error :: struct) :: no_return
      def after_boot_app_error(_error), do: nil

      defoverridable before_start_app: 0,
                     after_start_app: 0,
                     after_boot_app: 0,
                     after_boot_app_error: 1
    end
  end
end
