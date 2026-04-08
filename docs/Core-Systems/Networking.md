# Networking System

The Habbo client uses a custom binary protocol over TCP for client-server communication. This document details the networking architecture, protocol format, encryption, and message routing.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     NETWORKING ARCHITECTURE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                   HabboCommunicationManager                          │  │
│  │  - Connection lifecycle management                                   │  │
│  │  - Port failover handling                                            │  │
│  │  - Encryption initialization                                         │  │
│  │  - Message configuration                                            │  │
│  └───────────────────────────────┬───────────────────────────────────────┘  │
│                                  │                                           │
│                                  ▼                                           │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        SocketConnection                              │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐  │  │
│  │  │   Flash Socket │  │ EvaWireFormat  │  │    Encryption         │  │  │
│  │  │    (TCP)       │  │  (Encode/Dec)  │  │   (RC4 Stream Cipher)  │  │  │
│  │  └────────────────┘  └────────────────┘  └────────────────────────┘  │  │
│  │                                                                       │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │                   MessageClassManager                         │  │  │
│  │  │        (Maps message IDs ↔ Composer/Event classes)          │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────┬───────────────────────────────────────┘  │
│                                  │                                           │
│          ┌──────────────────────┼──────────────────────┐                    │
│          │                      │                      │                    │
│          ▼                      ▼                      ▼                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐        │
│  │   Outgoing       │  │    Incoming       │  │    Parsers      │        │
│  │   Composers      │  │   MessageEvents   │  │                 │        │
│  │                  │  │                  │  │                 │        │
│  │  ChatMessage     │  │  RoomUsersEvent   │  │ UserObjectParser│        │
│  │  Composer       │  │  ObjectsEvent    │  │                 │        │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Connection Management

### HabboCommunicationManager
**File:** `src/com/sulake/habbo/communication/HabboCommunicationManager.as`

The main class managing connection lifecycle:

```actionscript
public class HabboCommunicationManager extends Component 
    implements IHabboCommunicationManager, IConnectionStateListener 
{
    private var _connection:IConnection;
    private var _communication:ICoreCommunicationManager;
    private var _messages:IMessageConfiguration;
    private var _host:String = "";
    private var _ports:Array;
    private var _portIndex:int = -1;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `initComponent()` | Initialize connection system |
| `initConnection(k:String)` | Start connection (e.g., "HABBO_MAIN") |
| `updateHostParameters()` | Load host/port from config |
| `tryNextPort()` | Try next port on failure |
| `addHabboConnectionMessageEvent()` | Register message listener |

### Port Failover

The client tries multiple ports in sequence:

```actionscript
// Default ports (as byte values in server code)
_ports = [65162, 65162, 65158, 65155];  // Various ports
// Tries each port, 10 second timeout
// Retries cycle 2-3 times before giving up
```

## Protocol Format

### EvaWireFormat
**File:** `src/com/sulake/core/communication/wireformat/EvaWireFormat.as`

The Habbo protocol uses a simple binary format:

```
┌──────────────┬──────────────┬──────────────────────────┐
│ Length (4B)  │ Header (2B) │ Body (variable)          │
│ big-endian   │ big-endian  │                          │
│ int32        │ uint16     │ type-specific fields     │
└──────────────┴──────────────┴──────────────────────────┘
```

### Data Types

| Type | Size | Encoding |
|------|------|----------|
| `int` | 4 bytes | Big-endian signed 32-bit |
| `short` | 2 bytes | Big-endian signed 16-bit |
| `boolean` | 1 byte | `0x00` = false, `0x01` = true |
| `string` | 2 + N | 2-byte UTF-8 length prefix, then N bytes |
| `byte[]` | 4 + N | 4-byte length prefix, then N raw bytes |

### Encoding Process

```actionscript
// Encode (outgoing)
public function encode(header:int, message:Array):ByteArray
{
    var buffer:ByteArray = new ByteArray();
    buffer.writeInt(0);        // Placeholder for length
    buffer.writeShort(header); // Message ID
    
    for each (value in message) {
        if (value is String) {
            buffer.writeUTFBytes(value);
        } else if (value is int) {
            buffer.writeInt(value);
        } else if (value is Boolean) {
            buffer.writeByte(value ? 1 : 0);
        }
    }
    
    // Fix length
    buffer.writeInt(0, buffer.length - 4);
    return buffer;
}
```

### Decoding Process

```actionscript
// Decode (incoming)
public function decode(data:ByteArray):Array
{
    var messages:Array = [];
    var offset:int = 0;
    
    while (offset + 6 <= data.length) {
        var length:int = data.readInt();       // 4 bytes
        var header:int = data.readShort();     // 2 bytes
        
        var bodyLength:int = length - 2;
        var body:ByteArray = new ByteArray();
        if (bodyLength > 0) {
            data.readBytes(body, 0, bodyLength);
        }
        
        messages.push(new EvaMessageDataWrapper(header, body));
    }
    
    return messages;
}
```

## Message Composers (Outgoing)

### IMessageComposer Interface

All outgoing packets implement this interface:

```actionscript
public interface IMessageComposer
{
    function getMessageArray():Array;
    function dispose():void;
    function get disposed():Boolean;
}
```

### Example Composer

```actionscript
// src/com/sulake/habbo/communication/messages/outgoing/room/ChatMessageComposer.as
public class ChatMessageComposer implements IMessageComposer
{
    private var _message:String;
    private var _bubbleStyle:int = 0;
    
    public function ChatMessageComposer(message:String, bubbleStyle:int = 0)
    {
        this._message = message;
        this._bubbleStyle = bubbleStyle;
    }
    
    public function getMessageArray():Array
    {
        return [this._message, this._bubbleStyle];
    }
}
```

### Composer Directory Structure

```
communication/messages/outgoing/
├── handshake/        - Connection setup
│   ├── ClientHelloMessageComposer
│   ├── SSOTicketMessageComposer
│   └── ...
├── room/            - Room actions
│   ├── ChatMessageComposer
│   ├── MoveAvatarMessageComposer
│   ├── UseFurnitureMessageComposer
│   └── ...
├── catalog/         - Shop purchases
├── friendlist/      - Friends/messaging
├── inventory/       - Inventory actions
└── ... (500+ composers)
```

## Message Events (Incoming)

### MessageEvent Structure

```actionscript
// src/com/sulake/core/communication/messages/MessageEvent.as
public class MessageEvent implements IMessageEvent 
{
    protected var _callback:Function;
    protected var _parser:IMessageParser;
    protected var _connection:IConnection;
    
    public function MessageEvent(callback:Function, parserClass:Class) { }
}
```

### Event Handler Pattern

```actionscript
// Register listener
var event:MessageEvent = connection.addMessageEvent(
    new UserObjectEvent(onUserObject)
);

// Handler
private function onUserObject(event:UserObjectEvent):void
{
    var userData = event.userData;
    // Handle data
}
```

### IMessageParser Interface

```actionscript
public interface IMessageParser
{
    function flush():Boolean;
    function parse(k:IMessageDataWrapper):Boolean;
}
```

### Example Parser

```actionscript
public class UserObjectParser implements IMessageParser
{
    private var _userId:int;
    private var _username:String;
    private var _figure:String;
    
    public function flush():Boolean
    {
        return true;
    }
    
    public function parse(k:IMessageDataWrapper):Boolean
    {
        this._userId = k.readInteger();
        this._username = k.readString();
        this._figure = k.readString();
        return true;
    }
}
```

## Encryption

### RC4 (ArcFour) Stream Cipher
**File:** `src/com/sulake/habbo/communication/encryption/ArcFour.as`

Used for encrypting all traffic after handshake:

```actionscript
public class ArcFour implements IEncryption
{
    private var _S:ByteArray;  // 256-byte S-box
    
    public function init(k:ByteArray):void
    {
        // Key Scheduling Algorithm (KSA)
        for (var i:int = 0; i < 256; i++) {
            _S[i] = i;
        }
        var j:int = 0;
        for (var i:int = 0; i < 256; i++) {
            j = (j + _S[i] + k[i % k.length]) % 256;
            // Swap S[i] and S[j]
        }
    }
    
    public function encipher(k:ByteArray):ByteArray
    {
        // Pseudo-Random Generation Algorithm (PRGA)
        var i:int = 0, j:int = 0;
        var output:ByteArray = new ByteArray();
        for (var n:int = 0; n < k.length; n++) {
            i = (i + 1) % 256;
            j = (j + _S[i]) % 256;
            // Swap
            output.writeByte(k[n] ^ _S[(i + _S[j]) % 256]);
        }
        return output;
    }
}
```

### Diffie-Hellman Key Exchange
**File:** `src/com/sulake/habbo/communication/encryption/DiffieHellman.as`

Used to establish shared encryption key:

```
Client                                                   Server
  │                                                         │
  │──── InitDiffieHandshakeMessageComposer ──────────────>│
  │                                                         │
  │<─── InitDiffieHandshakeComposer ─────────────────────│
  │     (RSA-encrypted DH parameters)                      │
  │                                                         │
  │  (Client generates DH keypair)                         │
  │                                                         │
  │──── CompleteDiffieHandshakeMessageComposer ─────────>│
  │     (Client's DH public key)                          │
  │                                                         │
  │<─── CompleteDiffieHandshakeComposer ─────────────────│
  │     (Server confirms handshake)                        │
  │                                                         │
  │  ════ RC4 ENCRYPTED TRAFFIC ════                       │
```

### Encryption Flow

```actionscript
// After DH handshake completes:
var outgoing:ArcFour = new ArcFour();
outgoing.init(sharedSecret);  // From DH

var incoming:ArcFour = new ArcFour();
incoming.init(sharedSecret);

connection.setEncryption(outgoing, incoming);
```

## Message Routing

### HabboMessages Configuration
**File:** `src/com/sulake/habbo/communication/HabboMessages.as`

Maps message IDs to classes:

```actionscript
public class HabboMessages implements IMessageConfiguration
{
    private static const INCOMING_PACKETS:Map = new SingleWriteMap();
    private static const OUTGOING_PACKETS:Map = new SingleWriteMap();
    
    // Static initializer - 500+ mappings
    INCOMING_PACKETS[2725] = UserObjectEvent;
    INCOMING_PACKETS[374] = UsersEvent;
    INCOMING_PACKETS[1778] = ObjectsMessageEvent;
    // ... more
}
```

### Key Message IDs

| ID | Direction | Purpose |
|----|-----------|---------|
| 4000 | Out | ClientHello |
| 2490 | Out | UniqueID (machine ID) |
| 3110 | Out | InitDiffieHandshake |
| 773 | Out | CompleteDiffieHandshake |
| 2491 | In | AuthenticationOK |
| 758 | In | OpenConnection |
| 374 | In | Users (room users) |
| 1778 | In | Objects (room furniture) |

## Connection States

### HabboConnectionEvent States

```
NOT_CONNECTED → CONNECTING → CONNECTED
                  ↓
              HANDSHAKING → HANDSHAKED
                  ↓
              AUTHENTICATED
                  ↓
              DISCONNECTED
```

### State Events

| Event | Description |
|-------|-------------|
| `HABBO_CONNECTION_EVENT_ESTABLISHED` | Socket connected |
| `HABBO_CONNECTION_EVENT_HANDSHAKING` | Encryption handshake |
| `HABBO_CONNECTION_EVENT_HANDSHAKED` | Handshake complete |
| `HABBO_CONNECTION_EVENT_AUTHENTICATED` | Login successful |

## Key Files Reference

| File | Purpose |
|------|---------|
| `HabboCommunicationManager.as` | Connection manager |
| `SocketConnection.as` | TCP socket wrapper |
| `EvaWireFormat.as` | Binary protocol |
| `HabboMessages.as` | Message ID mappings |
| `ArcFour.as` | RC4 encryption |
| `DiffieHellman.as` | Key exchange |
| `MessageClassManager.as` | Message routing |
| `MessageEvent.as` | Incoming handler base |
| `IMessageComposer.as` | Outgoing interface |

## Next Steps

- [Room Engine Architecture](Core-Systems/Room-Engine/Architecture) - Room system
- [Data Flows - Client-Server](Data-Flows/Client-Server-Communication) - Packet flow diagram
- [Directory Structure](Architecture/Directory-Structure) - Package organization
