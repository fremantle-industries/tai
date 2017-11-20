defmodule Tai.Exchanges.Adapters.Test do
  def balance do
    Decimal.new(0.11)
  end

  def quotes(_symbol) do
    {
      %Tai.Quote{
        size: Decimal.new(1.55),
        price: Decimal.new(8003.21),
        age: Decimal.new(0.001044)
      },
      %Tai.Quote{
        size: Decimal.new(0.66),
        price: Decimal.new(8003.22),
        age: Decimal.new(0.000143)
      }
    }
  end
end
