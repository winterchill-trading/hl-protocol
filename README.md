# hl-protocol

Hyperliquid wire types and JSON codecs

Built with [OxCaml](https://oxcaml.org) and the Jane Street library stack (Base, Core).

## Build

```sh
opam switch create 5.2.0+ox --repos ox=git+https://github.com/oxcaml/opam-repository.git,default
opam pin add fixed-decimal https://github.com/winterchill-trading/fixed-decimal.git --no-action
opam pin add exchange-core https://github.com/winterchill-trading/exchange-core.git --no-action
opam install . --deps-only --with-test
dune build && dune test
```

CI installs the pinned siblings and the opam dependencies through the shared
[ox-setup](https://github.com/winterchill-trading/infra/blob/main/docs/ci.md) action, which
caches the built opam switch between runs.

## Modules

All modules live under `Hl_protocol`. Every type derives `sexp`, `compare`,
`equal` and `yojson` (via `ppx_yojson_conv`), and the JSON matches the shapes of
Hyperliquid's public HTTP and websocket API.

### Primitives

The venue-neutral primitives live in
[exchange-core](https://github.com/winterchill-trading/exchange-core) and are re-exported
here with type equalities (`Hl_protocol.Price.t = Exchange_core.Price.t`,
`Hl_protocol.Address.t = Exchange_core.Account.t`, ...), so values pass between the two
without conversion. This library adds Hyperliquid's JSON encodings and format rules.

| Module | Description |
| --- | --- |
| `Price`, `Size`, `Usd` | `Exchange_core.Price`, `Size`, `Usd`: distinct fixed-point types made with `Fixed_decimal.Make ()` from [fixed-decimal](https://github.com/winterchill-trading/fixed-decimal), encoded as decimal strings |
| `Coin` | `Exchange_core.Symbol`: asset name (`"BTC"`, `"@107"`) |
| `Asset` | Asset index used by the exchange endpoint (position in `Meta.universe`) |
| `Address` | `Exchange_core.Account`: account address, lowercased by `of_string` and the decoder |
| `Side` | `Exchange_core.Side`: `Buy` / `Sell`, encoded as `"B"` / `"A"` |
| `Tif` | `Exchange_core.Tif`: `Gtc` / `Ioc` / `Alo` |
| `Tpsl` | `Tp` / `Sl` for trigger orders |
| `Order_type` | `{"limit": {"tif": ...}}` or `{"trigger": {...}}` (Hyperliquid's own, not `Exchange_core.Order_type`) |
| `Order_id` | `Exchange_core.Order_id`: exchange order id (`int64`), a JSON integer |
| `Cloid` | `Exchange_core.Client_order_id` restricted to `0x` + 32 hex digits |
| `Json` | Opaque JSON values plus small decoding helpers |
| `Codec` | `module type S` satisfied by every wire type |

### Exchange endpoint (`POST /exchange`)

| Module | Description |
| --- | --- |
| `Order_request` | Order in compact wire form (`a`, `b`, `p`, `s`, `r`, `t`, `c`) |
| `Cancel_request` | Cancel by oid (`a`, `o`) |
| `Cancel_by_cloid` | Cancel by client id (`asset`, `cloid`) |
| `Modify_request` | Modify by oid or cloid |
| `Grouping` | `na` / `normalTpsl` / `positionTpsl` |
| `Exchange_action` | `order`, `cancel`, `cancelByCloid`, `modify` actions |
| `Exchange_request` | `{"action", "nonce", "signature", "vaultAddress"}` envelope (signature opaque) |
| `Order_status` | `resting` / `filled` / `error` / `waitingForFill` / `waitingForTrigger` |
| `Cancel_status` | `"success"` / `{"error": ...}` |
| `Exchange_response` | `{"status": "ok" \| "err", "response": ...}` |
| `Builder_fee` | The order action's `builder: {"b", "f"}` field (`f` in tenths of a basis point) and `maxFeeRate` percent strings |
| `Order_action` | `order` action with the optional `builder`; converts to and from `Exchange_action.Order` |
| `Exchange_envelope` | `Exchange_request` layout around a raw JSON action, plus `expiresAfter` |
| `User_signed_action` | `approveAgent` and `approveBuilderFee`, with their EIP-712 primary types and typed fields |
| `User_signed_request` | `{"action", "nonce", "signature"}` body for those, and a body classifier for servers |

### Info endpoint (`POST /info`)

| Module | Description |
| --- | --- |
| `Info_request` | `l2Book`, `allMids`, `openOrders`, `userFills`, `clearinghouseState`, `meta` |
| `Info_response` | Variant over the responses below, decoded given the request |
| `L2_book` | Book snapshot with bids and asks of `{px, sz, n}` |
| `All_mids` | Mid price per coin |
| `Open_order` | Resting order |
| `User_fill` | Fill record; `User_fill.Detailed` adds the optional `builderFee` and `liquidation` |
| `Clearinghouse_state` | Positions, leverage and margin summaries |
| `Meta` | Perp universe (`name`, `szDecimals`, `maxLeverage`) and coin/asset lookups |
| `User_fills_by_time` | `userFillsByTime` request (at most 2000 fills per response) |
| `Max_builder_fee` | `maxBuilderFee` request; the response is the approved cap in tenths of a basis point |

### Stats host

| Module | Description |
| --- | --- |
| `Leaderboard` | `GET stats-data.hyperliquid.xyz/<network>/leaderboard` rows: account value and pnl, roi, volume per window |

### WebSocket

| Module | Description |
| --- | --- |
| `Subscription` | `l2Book`, `trades`, `orderUpdates`, `userFills`, `allMids` |
| `Ws_request` | `subscribe` / `unsubscribe` / `ping` |
| `Trade` | Public trade |
| `Order_update` | Order status update |
| `Ws_message` | `{"channel", "data"}` messages decoded by channel |
| `Asset_ctx` | `activeAssetCtx` channel (funding, mark, oracle, volumes) and its (un)subscribe requests, carried as `Ws_message.Unknown` |
| `User_event` | `userEvents` subscription for any address (channel `user`: fills, funding, liquidation, nonUserCancel), carried as `Ws_message.Unknown` |

### Differences from the Hyperliquid API

- Signatures are carried as opaque JSON and never produced or checked.
- Numbers are re-encoded in their shortest form (`"113377.0"` becomes `"113377"`),
  and digits past the 8th decimal place are dropped when parsing.
- Response decoders ignore unknown fields. Only the fields listed above are kept.
- Unknown websocket channels decode to `Ws_message.Unknown`, and so do
  `subscriptionResponse` echoes of subscriptions `Subscription` does not model; unknown
  order statuses decode to `Order_update.Status.Other`.
- `activeAssetCtx` has no `Subscription` or `Ws_message` constructor yet, because
  consumers match those variants exhaustively. Build requests with
  `Asset_ctx.Request` and read messages with `Asset_ctx.of_ws_message`.
- `approveAgent`, `approveBuilderFee`, `userFillsByTime`, `maxBuilderFee`, `userEvents` and the order
  `builder` field live in their own modules rather than as new constructors of
  `Exchange_action`, `Info_request` or `Subscription`, for the same reason. A server that
  decodes `/exchange` bodies with `Exchange_request` accepts a builder order and drops
  the builder; `User_signed_request.is_user_signed_body` picks the approval decoder.
- `User_fill.t` ignores `builderFee` and `liquidation` on fills, so code that builds fill
  records keeps compiling; decode with `User_fill.Detailed` to keep them.
- `liquidationPx` decodes to `None` when absent, `null`, or outside the fixed-point range
  (about 4.6e10).

## Coverage against mainnet

Checked by tests that decode and re-encode real frames: `test/fixtures/mainnet-info-ws-2026-10-12`
(info responses and websocket frames of one market-making account, captured
2026-10-12, trimmed) and `test/fixtures/hyperliquid-BTC-2026-10-12T13-35` (a raw minute of
the BTC feed in the recorder format). Everything else is written from the API docs and
checked only against hand-written samples and the simulator.

| Endpoint | Message | Mainnet sample |
| --- | --- | --- |
| info | `allMids` | verified |
| info | `l2Book` | verified |
| info | `meta` | verified |
| info | `openOrders` | verified |
| info | `userFills` | verified |
| info | `clearinghouseState` | verified, including large and `null` `liquidationPx` |
| exchange | `order`, `cancel`, `cancelByCloid`, `modify` requests | unverified (no signing here) |
| exchange | `approveAgent`, `approveBuilderFee`, order `builder` | docs examples only |
| ws | `userEvents` | docs shapes only |
| stats | `leaderboard` | testnet sample (`test/fixtures/testnet-leaderboard-2026-10-13`) |
| exchange | `Exchange_response`, `Order_status`, `Cancel_status` | unverified |
| ws | `subscribe` / `unsubscribe` / `ping` requests | verified (the same JSON is accepted by mainnet) |
| ws | `subscriptionResponse` | verified (`l2Book` echoes add `nSigFigs`, `mantissa`, `fast`, which are dropped) |
| ws | `trades` | verified |
| ws | `l2Book` | verified |
| ws | `allMids` | verified |
| ws | `userFills` (snapshot and updates) | verified |
| ws | `orderUpdates` | verified |
| ws | `activeAssetCtx` (`Asset_ctx`) | verified for perps; spot shape from a sample only |
| ws | `pong`, `error` | verified |

