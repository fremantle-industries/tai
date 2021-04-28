defmodule Tai.DateTimeTest do
  use ExUnit.Case, async: false
  import Mock

  @today DateTime.utc_now()
  @yesterday DateTime.utc_now() |> Timex.shift(days: -1)

  test ".timestamp/1 proxies to DateTime.utc_now/1" do
    with_mock DateTime, utc_now: fn _ -> ~U[2020-01-02 03:04:05.123456Z] end do
      assert Tai.DateTime.timestamp(Calendar.ISO) == ~U[2020-01-02 03:04:05.123456Z]
    end
  end

  test ".min/1 returns the earliest value" do
    assert Tai.DateTime.min(@today, @yesterday) == @yesterday
  end

  test ".max/1 returns the latest value" do
    assert Tai.DateTime.max(@today, @yesterday) == @today
  end
end
