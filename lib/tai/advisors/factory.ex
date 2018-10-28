defprotocol Tai.Advisors.Factory do
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}

  @callback advisor_specs(
              group :: advisor_group,
              product_symbols_by_exchange :: map
            ) :: [advisor_spec]
end
