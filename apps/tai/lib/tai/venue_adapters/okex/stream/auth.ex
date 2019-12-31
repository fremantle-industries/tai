defmodule Tai.VenueAdapters.OkEx.Stream.Auth do
  @method "GET"
  @path "/users/self/verify"

  def args({
        _credential_id,
        %{api_key: api_key, api_secret: api_secret, api_passphrase: api_passphrase}
      }) do
    timestamp = ExOkex.Auth.timestamp()
    signed = ExOkex.Auth.sign(timestamp, @method, @path, %{}, api_secret)

    [
      api_key,
      api_passphrase,
      timestamp,
      signed
    ]
  end
end
