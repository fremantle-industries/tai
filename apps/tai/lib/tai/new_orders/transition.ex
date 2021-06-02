defprotocol Tai.NewOrders.Transition do
  @callback from :: [atom]
  @callback attrs(struct) :: keyword
end
