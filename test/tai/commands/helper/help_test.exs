defmodule Tai.Commands.Helper.HelpTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  test "show command usage" do
    assert capture_io(&Tai.Commands.Helper.help/0) == """
           * balance
           * products
           * fees
           * markets
           * orders
           * advisors
           * settings
           * start_advisors
           * start_advisor_group :group_id
           * start_advisor :group_id, :advisor_id
           * stop_advisors
           * stop_advisor_group :group_id
           * stop_advisor :group_id, :advisor_id
           * enable_send_orders
           * disable_send_orders\n
           """
  end
end
