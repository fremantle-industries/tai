defmodule Tai.Markets.PricePoint do
  @moduledoc """
  A level of a side in an order book
  """

  alias __MODULE__

  @type t :: %PricePoint{price: number, size: number}

  @enforce_keys ~w(price size)a
  defstruct ~w(price size)a

  def fetch(term, :price), do: {:ok, term.price}
  def fetch(term, :size), do: {:ok, term.size}
  def fetch(_, _), do: :error

  def get(structure, key, default) do
    case fetch(structure, key) do
      {:ok, value} -> value
      :error -> default
    end
  end
end
