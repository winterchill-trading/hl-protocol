# hl-protocol

Hyperliquid wire types and JSON codecs

Built with [OxCaml](https://oxcaml.org) and the Jane Street library stack (Base, Core, Async).

## Build

```sh
opam switch create 5.2.0+ox --repos ox=git+https://github.com/oxcaml/opam-repository.git,default
opam install . --deps-only --with-test
dune build && dune test
```

## Modules

All modules live under `Hl_protocol`. Every type derives `sexp`, `compare`,
`equal` and `yojson` (via `ppx_yojson_conv`), and the JSON matches the shapes of
Hyperliquid's public HTTP and websocket API.

### Primitives

| Module | Description |
| --- | --- |
| `Price`, `Size`, `Usd` | Distinct fixed-point types for prices, base-asset sizes and USD amounts, each made with `Fixed_decimal.Make ()` from the [fixed-decimal](https://github.com/winterchill-trading/fixed-decimal) library |
| `Coin` | Asset name (`"BTC"`, `"@107"`) |
| `Asset` | Asset index used by the exchange endpoint (position in `Meta.universe`) |
| `Address` | Account address, lowercased |
| `Side` | `Buy` / `Sell`, encoded as `"B"` / `"A"` |
| `Tif` | `Gtc` / `Ioc` / `Alo` |
| `Tpsl` | `Tp` / `Sl` for trigger orders |
| `Order_type` | `{"limit": {"tif": ...}}` or `{"trigger": {...}}` |
| `Order_id` | Exchange order id (`int64`) |
| `Cloid` | Client order id (`0x` + 32 hex digits) |
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

### Info endpoint (`POST /info`)

| Module | Description |
| --- | --- |
| `Info_request` | `l2Book`, `allMids`, `openOrders`, `userFills`, `clearinghouseState`, `meta` |
| `Info_response` | Variant over the responses below, decoded given the request |
| `L2_book` | Book snapshot with bids and asks of `{px, sz, n}` |
| `All_mids` | Mid price per coin |
| `Open_order` | Resting order |
| `User_fill` | Fill record |
| `Clearinghouse_state` | Positions, leverage and margin summaries |
| `Meta` | Perp universe (`name`, `szDecimals`, `maxLeverage`) and coin/asset lookups |

### WebSocket

| Module | Description |
| --- | --- |
| `Subscription` | `l2Book`, `trades`, `orderUpdates`, `userFills`, `allMids` |
| `Ws_request` | `subscribe` / `unsubscribe` / `ping` |
| `Trade` | Public trade |
| `Order_update` | Order status update |
| `Ws_message` | `{"channel", "data"}` messages decoded by channel |

### Differences from the Hyperliquid API

- Signatures are carried as opaque JSON and never produced or checked.
- Numbers are re-encoded in their shortest form (`"113377.0"` becomes `"113377"`),
  and digits past the 8th decimal place are dropped when parsing.
- Response decoders ignore unknown fields. Only the fields listed above are kept.
- Unknown websocket channels decode to `Ws_message.Unknown`, and unknown order
  statuses to `Order_update.Status.Other`.
