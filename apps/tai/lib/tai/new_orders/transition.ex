defprotocol Tai.NewOrders.Transition do
  @callback from :: [atom]
  @callback attrs(struct) :: keyword
  @callback status(current :: atom) :: atom
end
