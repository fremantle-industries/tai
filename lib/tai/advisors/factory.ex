defmodule Tai.Advisors.Factory do
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Venues.Product.t()

  @callback advisor_specs(group :: advisor_group, products :: [product]) :: [advisor_spec]
end
