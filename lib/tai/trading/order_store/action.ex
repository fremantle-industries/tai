defprotocol Tai.Trading.OrderStore.Action do
  @spec required(struct) :: atom | [atom]
  def required(action)

  @spec attrs(struct) :: map
  def attrs(action)
end
