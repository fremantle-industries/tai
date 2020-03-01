defmodule TaiEvents.EventTest do
  use ExUnit.Case, async: true

  describe ".encode!/1" do
    test "serializes events as json" do
      event = %{
        __struct__: Tai.Events.MyEvent,
        field_a: "Field A",
        field_b: "Field B"
      }

      assert TaiEvents.Event.encode!(event) ==
               %{
                 type: "Tai.Events.MyEvent",
                 data: %{
                   field_a: "Field A",
                   field_b: "Field B"
                 }
               }
               |> Jason.encode!()
    end

    test "can provide a custom data transformation" do
      event = %{
        __struct__: TaiEventsSupport.CustomEvent,
        hello: "world"
      }

      assert TaiEvents.Event.encode!(event) ==
               %{
                 type: "TaiEventsSupport.CustomEvent",
                 data: %{
                   hello: "custom"
                 }
               }
               |> Jason.encode!()
    end

    test "it encodes decimal values to string" do
      defmodule MyDecimalEvent do
        defstruct [:decimal]
      end

      event = %{
        __struct__: MyDecimalEvent,
        decimal: Decimal.new("42.1")
      }

      assert TaiEvents.Event.encode!(event) ==
               %{
                 type: "TaiEvents.EventTest.MyDecimalEvent",
                 data: %{
                   decimal: "42.1"
                 }
               }
               |> Jason.encode!()
    end
  end
end
