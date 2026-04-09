# Message Pattern

Every Habbo packet is represented by two or three ActionScript classes. This page explains the pattern so you can read/write messages in the codebase without grepping for examples each time.

See also: [Wire Format](Wire-Format) (byte layout) · [Encryption](Encryption) (RC4/DH) · [Packet Reference](Packet-Reference) (ID tables).

## The Three Roles

| Direction | Role          | Interface                                                                 | Naming                               |
|-----------|---------------|---------------------------------------------------------------------------|--------------------------------------|
| Incoming  | **Event**     | `com.sulake.core.communication.messages.IMessageEvent`                    | `XxxMessageEvent` / `XxxEvent`       |
| Incoming  | **Parser**    | `com.sulake.core.communication.messages.IMessageParser`                   | `XxxMessageParser` / `XxxParser`     |
| Outgoing  | **Composer**  | `com.sulake.core.communication.messages.IMessageComposer`                 | `XxxMessageComposer`                 |

**Event + Parser** is a pair: the event is what application code listens for and holds typed accessors; the parser is where bytes are actually read. They're split so the framework can share one parser instance across multiple listeners of the same packet (see `MessageClassManager.registerMessageEvent()` lines 76-96).

A **Composer** is a single class that exposes a flat `Array` of typed fields for the encoder to walk.

## Incoming: Event Class

Events extend `MessageEvent` and pass their paired parser class as the second constructor argument. Typed getters project fields from the parser so listeners don't have to cast.

```actionscript
package com.sulake.habbo.communication.messages.incoming.handshake
{
    import com.sulake.core.communication.messages.MessageEvent;
    import com.sulake.core.communication.messages.IMessageEvent;
    import com.sulake.habbo.communication.messages.parser.handshake.InitDiffieHandshakeParser;

    public class InitDiffieHandshakeEvent extends MessageEvent implements IMessageEvent
    {
        public function InitDiffieHandshakeEvent(k:Function)
        {
            super(k, InitDiffieHandshakeParser);
        }

        public function get encryptedPrime():String
        {
            return (this._parser as InitDiffieHandshakeParser).encryptedPrime;
        }

        public function get encryptedGenerator():String
        {
            return (this._parser as InitDiffieHandshakeParser).encryptedGenerator;
        }
    }
}
```

**Conventions:**
- Constructor signature is always `function(k:Function)` — the `k` is the listener callback. The parent `MessageEvent` stores both the callback and the parser class.
- The parser class reference is passed as `Class`, not as an instance. The framework instantiates it lazily on first subscribe.
- Getters forward to `(this._parser as XxxParser).field`. There is no direct field storage on the event.
- Events live in `src/com/sulake/habbo/communication/messages/incoming/<category>/`.

**Source:** `src/com/sulake/core/communication/messages/MessageEvent.as` (base class), `src/com/sulake/habbo/communication/messages/incoming/handshake/InitDiffieHandshakeEvent.as` (example).

## Incoming: Parser Class

The parser is where wire decoding happens. One method — `parse(IMessageDataWrapper)` — reads fields in a fixed order and stashes them on private members.

```actionscript
package com.sulake.habbo.communication.messages.parser.handshake
{
    import com.sulake.core.communication.messages.IMessageParser;
    import com.sulake.core.communication.messages.IMessageDataWrapper;

    public class InitDiffieHandshakeParser implements IMessageParser
    {
        private var _encryptedPrime:String;
        private var _encryptedGenerator:String;

        public function flush():Boolean { return true; }

        public function parse(k:IMessageDataWrapper):Boolean
        {
            this._encryptedPrime = k.readString();
            this._encryptedGenerator = k.readString();
            return true;
        }

        public function get encryptedPrime():String { return this._encryptedPrime; }
        public function get encryptedGenerator():String { return this._encryptedGenerator; }
    }
}
```

**Conventions:**
- `flush()` is used to reset per-invocation state; most parsers just `return true`.
- `parse()` must return `true` on success. Returning `false` signals a malformed frame; the framework will disconnect.
- Field order must match the sender's composition order exactly. There is no length, type, or name tagging in the wire format — positional only. See [Wire Format](Wire-Format).
- Parsers live in `src/com/sulake/habbo/communication/messages/parser/<category>/` — **not** alongside the events.

**Read methods** available on `IMessageDataWrapper`: `readString`, `readInteger`, `readBoolean`, `readShort`, `readByte`, `readFloat`, `readDouble`, and `bytesAvailable` for optional trailing fields (see `CompleteDiffieHandshakeParser` for an example of conditional parsing).

## Outgoing: Composer Class

Composers are trivial: they hold field values and return them as an `Array` in encode order.

```actionscript
package com.sulake.habbo.communication.messages.outgoing.handshake
{
    import com.sulake.core.communication.messages.IMessageComposer;
    import com.sulake.core.communication.messages.IPreEncryptionMessage;

    public class CompleteDiffieHandshakeMessageComposer implements IMessageComposer, IPreEncryptionMessage
    {
        private var _publicKey:String;

        public function CompleteDiffieHandshakeMessageComposer(k:String)
        {
            this._publicKey = k;
        }

        public function dispose():void { }

        public function getMessageArray():Array
        {
            return [this._publicKey];
        }
    }
}
```

**Conventions:**
- Accept field values in the constructor.
- Return them — in wire order — from `getMessageArray()`.
- Type in the array determines encoding:
  - `String` → `writeUTF` (2-byte length + UTF-8)
  - `int` → 4-byte int
  - `Boolean` → 1 byte
  - **`Short`** (wrapper class) → 2 bytes. **Plain `int` does not work for 2-byte fields** — wrap with `new Short(value)`.
  - `ByteArray` → 4-byte length + raw bytes

See `EvaWireFormat.encode()` at `src/com/sulake/core/communication/wireformat/EvaWireFormat.as:16-63` for the dispatch order.

### `IPreEncryptionMessage` marker

Composers that must be sent **before the handshake completes** additionally implement `IPreEncryptionMessage`. The connection's send path inspects this marker and routes via `sendUnencrypted()` instead of the normal encrypted path. Only the four handshake composers use it:

- `ClientHelloMessageComposer`
- `InitDiffieHandshakeMessageComposer`
- `CompleteDiffieHandshakeMessageComposer`
- (check `IPreEncryptionMessage.as` usages for current list)

**Source:** `src/com/sulake/core/communication/messages/IPreEncryptionMessage.as`

## ID Registration

None of the three classes know their own packet ID. Instead, `HabboMessages.as` is the single source of truth — it maps integer IDs to Event and Composer classes in two static `Map`s:

```actionscript
// src/com/sulake/habbo/communication/HabboMessages.as:989-992
public class HabboMessages implements IMessageConfiguration
{
    private static const INCOMING_PACKETS:Map = new SingleWriteMap();
    private static const OUTGOING_PACKETS:Map = new SingleWriteMap();

    // Static initializer block ~line 994 onwards:
    // INCOMING_PACKETS[1347] = InitDiffieHandshakeEvent;
    // OUTGOING_PACKETS[773]  = CompleteDiffieHandshakeMessageComposer;
```

These maps feed `MessageClassManager.registerMessages()` at boot (see `src/com/sulake/core/communication/messages/MessageClassManager.as:36-46`), which builds reverse lookups so:

- When a frame arrives, its 2-byte ID is used to find the Event class, instantiate the paired Parser, and dispatch to subscribed callbacks.
- When you `connection.send(new XxxComposer(...))`, the framework calls `getMessageIDForComposer()` (line 122) to look up the ID, prepends it to the encoded array, and writes the frame.

**Ramification:** to add a new packet you must (1) write the class(es), (2) add an entry to `HabboMessages.as`. Skipping step 2 will crash as soon as `send()` is called — `getMessageIDForComposer()` logs a login-step error and returns `-1`.

### Finding a packet ID

Two ways:

1. **Class → ID:** grep `HabboMessages.as` for the class name.
   ```bash
   grep -n "InitDiffieHandshakeEvent\b" src/com/sulake/habbo/communication/HabboMessages.as
   ```
2. **ID → Class:** grep for the literal ID with brackets.
   ```bash
   grep -n "INCOMING_PACKETS\[1347\]" src/com/sulake/habbo/communication/HabboMessages.as
   ```

See [Packet Reference](Packet-Reference) for pre-built per-category ID tables.

## Directory Layout

```
src/com/sulake/habbo/communication/messages/
├── incoming/
│   ├── handshake/              ← Event classes (XxxMessageEvent)
│   ├── room/
│   ├── catalog/
│   └── …
├── parser/
│   ├── handshake/              ← Parser classes (XxxMessageParser)
│   ├── room/
│   ├── catalog/
│   └── …
└── outgoing/
    ├── handshake/              ← Composer classes (XxxMessageComposer)
    ├── room/
    └── …
```

**Gotcha:** parsers are in their own top-level folder, **not** nested under `incoming/`. If you're looking for an incoming message's byte layout, go to `parser/<category>/XxxParser.as`, not `incoming/<category>/`.

## Adding a New Packet — Checklist

### Incoming
1. Create `src/com/sulake/habbo/communication/messages/parser/<cat>/FooParser.as` implementing `IMessageParser`.
2. Create `src/com/sulake/habbo/communication/messages/incoming/<cat>/FooEvent.as` extending `MessageEvent`, passing `FooParser` to `super()`.
3. Add `import` lines for both to `HabboMessages.as`.
4. Add `INCOMING_PACKETS[<id>] = FooEvent;` to the `HabboMessages` static initializer block.
5. Subscribe: `communication.addHabboConnectionMessageEvent(new FooEvent(onFoo));`

### Outgoing
1. Create `src/com/sulake/habbo/communication/messages/outgoing/<cat>/FooMessageComposer.as` implementing `IMessageComposer`, returning the field array from `getMessageArray()`.
2. Add `import` + `OUTGOING_PACKETS[<id>] = FooMessageComposer;` to `HabboMessages.as`.
3. Send: `connection.send(new FooMessageComposer(args));`

If the message must go out before the handshake completes, also implement `IPreEncryptionMessage` and use `connection.sendUnencrypted()`.

## Key Files

| File | Purpose |
|------|---------|
| `src/com/sulake/core/communication/messages/IMessageEvent.as`       | Event interface |
| `src/com/sulake/core/communication/messages/MessageEvent.as`        | Base class events extend |
| `src/com/sulake/core/communication/messages/IMessageParser.as`      | Parser interface |
| `src/com/sulake/core/communication/messages/IMessageComposer.as`    | Composer interface |
| `src/com/sulake/core/communication/messages/IPreEncryptionMessage.as` | Marker: route via `sendUnencrypted()` |
| `src/com/sulake/core/communication/messages/IMessageDataWrapper.as` | Typed reader used by parsers |
| `src/com/sulake/core/communication/messages/MessageClassManager.as` | ID registry + lookup runtime |
| `src/com/sulake/habbo/communication/HabboMessages.as`               | The canonical ID → class map |
