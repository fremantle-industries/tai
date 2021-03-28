defmodule Tai.Time do
  @monotonic_unit :microsecond

  @spec monotonic_unit :: :microsecond
  def monotonic_unit, do: @monotonic_unit

  @spec monotonic_time :: integer
  def monotonic_time, do: System.monotonic_time(@monotonic_unit)

  @spec monotonic_to_date_time(integer, :native | System.time_unit(), Calendar.calendar()) ::
          {:ok, DateTime.t()} | {:error, atom}
  def monotonic_to_date_time(mono, unit \\ @monotonic_unit, calendar \\ Calendar.ISO) do
    (mono + System.time_offset(unit))
    |> DateTime.from_unix(unit, calendar)
  end

  @spec monotonic_to_date_time!(integer, :native | System.time_unit(), Calendar.calendar()) ::
          DateTime.t()
  def monotonic_to_date_time!(mono, unit \\ @monotonic_unit, calendar \\ Calendar.ISO) do
    {:ok, value} = monotonic_to_date_time(mono, unit, calendar)
    value
  end
end
