defmodule Support.StartVenueAdapter do
  defmacro __using__(_) do
    quote do
      def stream_supervisor, do: Support.StartStreamSupervisor

      def products(_venue_id) do
        {:ok, []}
      end

      def accounts(_venue_id, _credential_id, _credentials) do
        {:ok, []}
      end

      def positions(_venue_id, _credential_id, _credentials) do
        {:ok, []}
      end

      def maker_taker_fees(_, _, _) do
        {:ok, nil}
      end

      defoverridable products: 1, accounts: 3, positions: 3, maker_taker_fees: 3
    end
  end
end
