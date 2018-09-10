defmodule Tai.Exchanges.FeeInfo do
  @type t :: %Tai.Exchanges.FeeInfo{}

  @enforce_keys [
    :exchange_id,
    :account_id,
    :symbol,
    :maker,
    :maker_type,
    :taker,
    :taker_type
  ]
  defstruct [
    :exchange_id,
    :account_id,
    :symbol,
    :maker,
    :maker_type,
    :taker,
    :taker_type
  ]

  def percent, do: :percent
end
