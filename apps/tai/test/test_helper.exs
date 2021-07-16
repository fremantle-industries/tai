ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier])
Ecto.Adapters.SQL.Sandbox.mode(Tai.Orders.OrderRepo, :manual)
ExUnit.start()
