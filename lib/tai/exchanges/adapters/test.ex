defmodule Tai.Exchanges.Adapters.Test do
  def balance do
    Decimal.new(0.11)
  end

  def quotes(_symbol) do
    {
      %Tai.Quote{
        volume: Decimal.new(1.55),
        price: Decimal.new(8003.21),
        age: 1044
      },
      %Tai.Quote{
        volume: Decimal.new(0.66),
        price: Decimal.new(8003.22),
        age: 143
      }
    }
  end
end
