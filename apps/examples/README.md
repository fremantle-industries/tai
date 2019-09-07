# Examples

### [Log the spread of every order book](./lib/examples/log_spread)

```bash
# log/dev.log
09:41:35.950 [info] {"type":"Examples.LogSpread.Events.Spread","data":{"venue_id":"gdax","spread":"0.01","product_symbol":"btc_usd","bid_price":"5491.05","ask_price":"5491.06"}}
09:41:37.211 [info] {"type":"Examples.LogSpread.Events.Spread","data":{"venue_id":"binance","spread":"1.76","product_symbol":"btc_usdt","bid_price":"5620.64","ask_price":"5622.4"}}
09:41:37.686 [info] {"type":"Examples.LogSpread.Events.Spread","data":{"venue_id":"gdax","spread":"0.01","product_symbol":"btc_usd","bid_price":"5491.05","ask_price":"5491.06"}}
09:41:37.862 [info] {"type":"Examples.LogSpread.Events.Spread","data":{"venue_id":"poloniex","spread":"6.75064342","product_symbol":"btc_usdt","bid_price":"5615.60680303","ask_price":"5622.35744645"}}
09:41:38.214 [info] {"type":"Examples.LogSpread.Events.Spread","data":{"venue_id":"binance","spread":"1.77","product_symbol":"btc_usdt","bid_price":"5620.64","ask_price":"5622.41"}}
```

### [Ping/Pong a passive maker order](./lib/examples/ping_pong)

```bash
# log/dev.log
20:40:10.751 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"0","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":null,"last_venue_timestamp":null,"leaves_qty":"100000","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"enqueued","time_in_force":"gtc","type":"limit","updated_at":null,"venue_id":"bitmex","venue_order_id":null},"type":"Tai.OrderUpdated"}
20:40:10.966 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"0","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":"2019-09-07T20:40:10.948996Z","last_venue_timestamp":"2019-09-07T20:40:10.860Z","leaves_qty":"100000","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"open","time_in_force":"gtc","type":"limit","updated_at":"2019-09-07T20:40:10.965915Z","venue_id":"bitmex","venue_order_id":"98dade7e-c5ee-6e10-99b7-afe464770b45"},"type":"Tai.OrderUpdated"}
20:43:24.529 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"36054","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":"2019-09-07T20:43:24.529391Z","last_venue_timestamp":"2019-09-07T20:43:24.419Z","leaves_qty":"63946","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"partially_filled","time_in_force":"gtc","type":"limit","updated_at":"2019-09-07T20:43:24.529728Z","venue_id":"bitmex","venue_order_id":"98dade7e-c5ee-6e10-99b7-afe464770b45"},"type":"Tai.OrderUpdated"}
20:43:34.625 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"46054","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":"2019-09-07T20:43:34.625224Z","last_venue_timestamp":"2019-09-07T20:43:34.523Z","leaves_qty":"53946","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"partially_filled","time_in_force":"gtc","type":"limit","updated_at":"2019-09-07T20:43:34.625598Z","venue_id":"bitmex","venue_order_id":"98dade7e-c5ee-6e10-99b7-afe464770b45"},"type":"Tai.OrderUpdated"}
20:43:41.115 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"46064","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":"2019-09-07T20:43:41.115025Z","last_venue_timestamp":"2019-09-07T20:43:41.014Z","leaves_qty":"53936","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"partially_filled","time_in_force":"gtc","type":"limit","updated_at":"2019-09-07T20:43:41.115545Z","venue_id":"bitmex","venue_order_id":"98dade7e-c5ee-6e10-99b7-afe464770b45"},"type":"Tai.OrderUpdated"}
20:44:19.632 [info] {"data":{"account_id":"main","client_id":"1b570fe3-7c15-4df9-945d-1ee3ba91d2ad","close":null,"cumulative_qty":"56064","enqueued_at":"2019-09-07T20:40:10.751451Z","error_reason":"nil","last_received_at":"2019-09-07T20:44:19.631704Z","last_venue_timestamp":"2019-09-07T20:44:19.512Z","leaves_qty":"43936","price":"10493.0","product_symbol":"xbtusd","product_type":"future","qty":"100000","side":"buy","status":"partially_filled","time_in_force":"gtc","type":"limit","updated_at":"2019-09-07T20:44:19.632250Z","venue_id":"bitmex","venue_order_id":"98dade7e-c5ee-6e10-99b7-afe464770b45"},"type":"Tai.OrderUpdated"}
```
