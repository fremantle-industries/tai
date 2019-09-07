defmodule Tai.TestSupport.E2ECase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ExUnit.CaptureIO
      import Tai.TestSupport.Assertions.Event

      setup do
        on_exit(fn -> stop_app() end)

        start_mock_server()
        before_app_start()
        start_app()
        after_app_start()
        :ok
      end

      @spec before_app_start :: no_return
      def before_app_start, do: nil

      @spec after_app_start :: no_return
      def after_app_start, do: nil

      def start_mock_server do
        start_supervised!(Tai.TestSupport.Mocks.Server)
      end

      def start_app do
        {:ok, _} = Application.ensure_all_started(:echo_boy)
        {:ok, _} = e2e_app() |> Application.ensure_all_started()
        Tai.Settings.enable_send_orders!()
        Tai.Events.firehose_subscribe()
      end

      def stop_app do
        :ok = Application.stop(:echo_boy)
        :ok = Application.stop(:tai)
        :ok = e2e_app() |> Application.stop()
      end

      def seed_mock_responses(scenario_name) do
        scenario = fetch_mod!(scenario_name)
        scenario.seed_mock_responses(scenario_name)
      end

      def push_stream_market_data({scenario_name, _, _, _} = args) do
        scenario = fetch_mod!(scenario_name)
        scenario.push_stream_market_data(args)
      end

      def push_stream_order_update({scenario_name, _, _, _} = scenario_args, client_id) do
        scenario = fetch_mod!(scenario_name)
        scenario.push_stream_order_update(scenario_args, client_id)
      end

      def configure_advisor_group(scenario_name) do
        scenario = fetch_mod!(scenario_name)
        advisor_group_config = scenario.advisor_group_config(scenario_name)

        Tai.Config
        |> struct(advisor_groups: Map.put(%{}, scenario_name, advisor_group_config))
        |> Tai.Advisors.Specs.from_config()
        |> Enum.map(&Tai.Advisors.Instance.from_spec/1)
        |> Enum.map(&Tai.Advisors.Store.upsert/1)
      end

      def start_advisors(args) do
        capture_io(fn -> Tai.CommandsHelper.start_advisors(args) end)
      end

      defp e2e_app, do: Application.fetch_env!(:tai, :e2e_app)

      defp fetch_mod!(scenario_name) do
        e2e_app()
        |> Application.get_env(:e2e_mappings, %{})
        |> Map.fetch!(scenario_name)
      end

      defoverridable before_app_start: 0, after_app_start: 0
    end
  end
end
