defprotocol Tai.Orders.Transition do
  @type t :: struct

  @spec required(struct) :: atom | [atom]
  def required(transition)

  @spec attrs(struct) :: map
  def attrs(transition)
end
