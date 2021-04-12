defmodule Tai.DateTimeTest do
  use ExUnit.Case, async: false

  @today DateTime.utc_now()
  @yesterday DateTime.utc_now() |> Timex.shift(days: -1)

  test ".min/1 returns the earliest value" do
    assert Tai.DateTime.min(@today, @yesterday) == @yesterday
  end

  test ".max/1 returns the latest value" do
    assert Tai.DateTime.max(@today, @yesterday) == @today
  end
end
