defmodule Tai.Markets.PriceLevel do
  @moduledoc """
  A level of a side in an order book
  """

  @type t :: %Tai.Markets.PriceLevel{
          price: number,
          size: number,
          processed_at: DateTime.t(),
          server_changed_at: DateTime.t() | nil
        }

  @enforce_keys [:price, :size, :processed_at]
  defstruct [:price, :size, :processed_at, :server_changed_at]

  def fetch(term, :price), do: {:ok, term.price}
  def fetch(term, :size), do: {:ok, term.size}
  def fetch(term, :processed_at), do: {:ok, term.processed_at}
  def fetch(term, :server_changed_at), do: {:ok, term.server_changed_at}
  def fetch(_, _), do: :error

  def get(structure, key, default) do
    case fetch(structure, key) do
      {:ok, value} -> value
      :error -> default
    end
  end
end
