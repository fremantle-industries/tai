defprotocol Tai.Trading.OrderStore.Action do
  @type t :: struct

  @spec required(struct) :: atom | [atom]
  def required(action)

  @spec attrs(struct) :: map
  def attrs(action)
end
