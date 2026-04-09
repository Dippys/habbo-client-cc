# Wire Format (EvaWireFormat)

The Habbo client speaks a length-prefixed binary protocol over TCP called **EvaWireFormat**. All traffic between client and server is framed using this format. This page documents the byte layout; see [Encryption](Encryption) for how these frames are wrapped in RC4, and [Message Pattern](Message-Pattern) for how ActionScript classes map to the encoded bytes.

## Frame Layout

Every packet — incoming or outgoing — is a single frame with three sections:

```
┌─────────────────┬─────────┬─────────────────────────┐
│  Length (4B)    │ ID (2B) │      Payload (N)        │
│  Big-endian     │         │                         │
│  int32          │ short   │  Concatenated fields    │
└─────────────────┴─────────┴─────────────────────────┘
  ↑                 ↑
  excludes itself   included in Length
  = 2 + N
```

- **Length** (4 bytes, big-endian signed int) — the number of bytes that follow. This is `2 (ID) + N (payload)`, so it excludes the length field itself. Minimum legal value is `2` (ID only, empty payload).
- **ID** (2 bytes, big-endian signed short) — the packet header / message ID. Mapped to a class in `HabboMessages.as`. See [Packet Reference](Packet-Reference).
- **Payload** (variable) — a concatenation of typed fields in a well-known order. Each message class defines its own field order; there is no field tagging.

**Source:** `src/com/sulake/core/communication/wireformat/EvaWireFormat.as:16-63` (encode), `:65-133` (decode).

## Field Type Encoding

The encoder in `EvaWireFormat.encode()` accepts six concrete types. It inspects each element with `is` checks in this order:

| AS3 Type  | Bytes On Wire             | Notes                                                                 |
|-----------|---------------------------|-----------------------------------------------------------------------|
| `String`  | `short length` + UTF-8    | Written via `ByteArray.writeUTF()`. Length is 2-byte unsigned short. |
| `int`     | 4 bytes, big-endian       | `ByteArray.writeInt()` — signed 32-bit                               |
| `Boolean` | 1 byte (`0x00` / `0x01`)  | `ByteArray.writeBoolean()`                                           |
| `Short`   | 2 bytes, big-endian       | Custom wrapper `com.sulake.core.communication.util.Short`            |
| `ByteArray` | `int length` + raw bytes | 4-byte length prefix + raw bytes                                     |

**Type-check order matters.** Since `Short` is a user class (not a primitive), you must wrap a `short` field in `new Short(value)` — passing a plain AS3 `int` will encode as 4 bytes instead of 2. Omitted types (e.g. `Number`/`double`) will silently fall through and encode nothing.

## Reading a Frame

Incoming frames are decoded by `EvaWireFormat.decode(buffer, socket)`:

1. Read 4 bytes → `messageLength` (big-endian int, decrypted if encryption is attached — see [Encryption](Encryption)).
2. Validate: `messageLength >= 2`. If not, the whole decode returns `null` (connection will be torn down).
3. If fewer than `messageLength` bytes are available, rewind buffer position and return what's parsed so far — the connection will retry when more bytes arrive. This is why `encryption.mark()`/`reset()` exist.
4. Copy `messageLength` bytes into a new `ByteArray`, decrypt if needed.
5. Read the first 2 bytes → packet ID (big-endian short).
6. Wrap the remaining bytes in an `EvaMessageDataWrapper` and hand it to the registered `IMessageParser` for that ID.

**Buffered decode:** a single call to `decode()` can emit multiple `EvaMessageDataWrapper` entries if the TCP read produced several complete frames. This is why the decoder loops until it runs out of data.

## Reading Payload Fields

Once a parser has its `IMessageDataWrapper`, it reads fields sequentially using typed accessors from `EvaMessageDataWrapper`:

**Source:** `src/com/sulake/core/communication/wireformat/EvaMessageDataWrapper.as`

| Method              | Bytes | Returns  |
|---------------------|-------|----------|
| `readString()`      | `short len + UTF-8` | `String` |
| `readInteger()`     | 4     | `int`    |
| `readBoolean()`     | 1     | `Boolean`|
| `readShort()`       | 2     | `int`    |
| `readByte()`        | 1     | `int`    |
| `readFloat()`       | 4     | `Number` |
| `readDouble()`      | 8     | `Number` |
| `bytesAvailable`    | —     | `uint`   |

**Note:** The wrapper exposes `readFloat`/`readDouble`/`readByte` for reading, but the encoder does **not** emit them — Habbo never sends floats or individual bytes from the client. These read methods exist mainly to support server-originated payloads and custom room/wired data streams that embed their own sub-format.

## Worked Example: `InitDiffieHandshakeEvent`

Server sends packet ID `1347` with two strings (`encryptedPrime`, `encryptedGenerator`). Wire bytes:

```
┌────────────┬──────┬───────────────────────┬───────────────────────────┐
│ 00 00 00 36│05 43 │ 00 10 "4a7b…" (16B)   │ 00 20 "b3c9…" (32B)       │
└────────────┴──────┴───────────────────────┴───────────────────────────┘
 length=54    1347    string: 2+16          string: 2+32
              (id)
```

Total on-wire size: `4 (length) + 2 (id) + 2+16 (prime) + 2+32 (generator) = 58 bytes`. The length field value is `58 - 4 = 54` (`0x36`).

**Parser:** `src/com/sulake/habbo/communication/messages/parser/handshake/InitDiffieHandshakeParser.as:17-22`

```actionscript
public function parse(k:IMessageDataWrapper):Boolean
{
    this._encryptedPrime = k.readString();
    this._encryptedGenerator = k.readString();
    return true;
}
```

## Framing Constants and Limits

- **Maximum data:** `MAX_DATA = 128 * 1024 = 131072` bytes is defined in `EvaWireFormat.as:10` but is currently **not enforced** (the check on line 101 is commented out). In practice the server decides what it sends.
- **Minimum length:** 2 bytes (ID only, no payload).
- **Byte order:** All multi-byte integers are big-endian (AS3 `ByteArray` default).
- **No checksums, no field tags.** The format is entirely positional and trusts both sides to know the schema for each ID.

## Key Files

| File                                                                             | Purpose                                  |
|----------------------------------------------------------------------------------|------------------------------------------|
| `src/com/sulake/core/communication/wireformat/EvaWireFormat.as`                  | `encode()` / `decode()` implementation   |
| `src/com/sulake/core/communication/wireformat/EvaMessageDataWrapper.as`          | Typed reader wrapping a decoded payload  |
| `src/com/sulake/core/communication/wireformat/IWireFormat.as`                    | Interface                                |
| `src/com/sulake/core/communication/messages/IMessageDataWrapper.as`              | Reader interface parsers depend on       |
| `src/com/sulake/core/communication/util/Short.as`                                | 2-byte field wrapper used by composers   |

## See Also

- [Encryption](Encryption) — how length and payload are enciphered with RC4
- [Message Pattern](Message-Pattern) — how ActionScript event/parser/composer classes map to these bytes
- [Packet Reference](Packet-Reference) — ID → class mapping tables
- [Core-Systems/Networking](../Core-Systems/Networking) — higher-level connection and message dispatch
