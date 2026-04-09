# Client-Server Communication

This document details the complete data flow from user action to server response, covering connection establishment, message routing, and error handling.

## Connection Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CLIENT-SERVER COMMUNICATION FLOW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    CONNECTION ESTABLISHMENT                         │   │
│  │                                                                       │   │
│  │  1. initConnection() ──► tryNextPort()                              │   │
│  │  2. Socket.connect() ──► Event.CONNECT                               │   │
│  │  3. ClientHello (unencrypted)                                        │   │
│  │  4. Server: InitDiffieHandshake                                       │   │
│  │  5. Diffie-Hellman key exchange                                      │   │
│  │  6. CompleteDiffieHandshake (encrypted)                             │   │
│  │  7. Server: Auth OK                                                  │   │
│  │  8. _authenticated = true                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      OUTGOING FLOW                                  │   │
│  │                                                                       │   │
│  │  UI Action ──► Composer.getMessageArray() ──► EvaWireFormat.encode  │   │
│  │       │                                  │                         │   │
│  │       │                                  ▼                         │   │
│  │       │                            ArcFour.encipher()              │   │
│  │       │                                  │                         │   │
│  │       │                                  ▼                         │   │
│  │       └──────────────────────► Socket.writeBytes()                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      INCOMING FLOW                                   │   │
│  │                                                                       │   │
│  │  Socket.onData ──► EvaWireFormat.decode ──► ArcFour.decipher        │   │
│  │       │                                    │                        │   │
│  │       │                                    ▼                        │   │
│  │       │                              Parser.parse()                 │   │
│  │       │                                    │                        │   │
│  │       │                                    ▼                        │   │
│  │       └───────────────────► Event.callback ──► UI Update           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Connection Establishment

### Initialization

```
Application Startup
        │
        ▼
HabboCommunicationManager.initComponent()
        │
        ├── Creates IConnection via CoreCommunicationManager
        ├── Registers message classes via HabboMessages
        ├── Adds error listeners (IO_ERROR, SECURITY_ERROR, CONNECT)
        └── Waits for configuration completion
```

### Connection Request

```
initConnection(HABBO_MAIN)
        │
        ├── tryNextPort() - iterates through available ports
        ├── SocketConnection.init(host, port)
        │
        └── Socket.connect() - TCP connection
               │
               ├── Event.CONNECT on success
               └── IO_ERROR on failure
```

### Handshake Sequence

```
1. Send ClientHello (UNENCRYPTED)
        │
2. Server: InitDiffieHandshake (ID: 1347)
        │
3. onInitDiffieHandshake():
        ├── Decrypt DH parameters (RSA)
        ├── Generate client key pair
        └── Send CompleteDiffieHandshakeMessageComposer
        │
4. Server: CompleteDiffieHandshake (ID: 1405)
        │
5. onCompleteDiffieHandshake():
        ├── Generate shared secret
        ├── Initialize ArcFour encryption
        └── connection.setEncryption(outgoing, incoming)
        │
6. Send connection parameters (ENCRYPTED):
        ├── VersionCheckMessageComposer (ID: 4000)
        ├── UniqueIDMessageComposer (ID: 4001)
        └── SSOTicketMessageComposer (ID: 4002)
        │
7. Server: AuthenticationOK (ID: 4609)
        │
8. onAuthenticationOK():
        ├── _authenticated = true
        ├── Process pending messages
        └── Send InfoRetrieveMessageComposer
```

## Outgoing Message Flow

### Composer -> Connection -> Server

```
[Application Logic]
        │
        ▼
[connection.send(MessageComposer)]
        │
        ├── MessageClassManager.getMessageIDForComposer()
        │       Returns message ID (e.g., 1405 for CompleteDiffieHandshake)
        │
        ├── Composer.getMessageArray()
        │       Returns Array of message data
        │
        ├── EvaWireFormat.encode(header, data)
        │       │
        │       └── Writes: [4 bytes length] + [2 bytes header] + [data]
        │               - String: writeUTF()
        │               - Int: writeInt()
        │               - Boolean: writeBoolean()
        │
        ├── IConnectionStateListener.messageSent(id)
        │       Logging purposes
        │
        ├── ArcFour.encipher(ByteArray)
        │       RC4 stream cipher
        │
        └── Socket.writeBytes() + Socket.flush()
```

### Key Outgoing Messages

| ID | Composer | Purpose |
|----|----------|---------|
| 4000 | VersionCheckMessageComposer | Client version |
| 4002 | SSOTicketMessageComposer | Authentication |
| 2900 | ChatMessageComposer | Chat messages |
| 1416 | MoveAvatarMessageComposer | Avatar movement |
| 18 | PongMessageComposer | Ping response |

### Unencrypted Messages

- ClientHelloMessageComposer - First message in handshake
- CompleteDiffieHandshakeMessageComposer - First encrypted after DH

## Incoming Message Flow

### Server -> Parser -> Handler -> UI

```
[Socket Event: SOCKET_DATA]
        │
        ├── Read bytes into _dataBuffer
        │
        ├── connection.processReceivedData()
        │       │
        │       └── EvaWireFormat.decode()
        │               │
        │               ├── Decrypt Length (if encrypted)
        │               ├── Read Message Length
        │               ├── Decrypt Content (if encrypted)
        │               ├── Read Header (2 bytes)
        │               └── Create EvaMessageDataWrapper(header, data)
        │
        ├── Split into individual messages
        ├── Handle incomplete messages (buffer remaining)
        │
        ├── parseReceivedMessage()
        │       │
        │       └── MessageClassManager.getMessageEventsForID(header)
        │               Returns Array of registered IMessageEvent
        │
        ├── Parser.flush() + Parser.parse(wrapper)
        │       Parses binary data into structured objects
        │
        └── handleReceivedMessage()
                │
                └── For each registered event handler:
                        ├── Set event.connection
                        └── Call event.callback(event)
```

### Message Event Architecture

```
[Server Message] ──► [MessageEvent] ──► [Callback Function]
                            │
                            ▼
                     [MessageParser] (parses data)
                            │
                            ▼
                     [Parser.getData()] (returns parsed data)
```

## Key Message Sequences

### Room Entry

```
[Out] OpenFlatConnectionMessageComposer (ID: 3001)
        │
        ▼
[In] RoomReadyMessageEvent (ID: 120)
        │
        ├── FloorHeightMapEvent (ID: 1301)
        ├── RoomPropertyMessageEvent
        ├── ItemsEvent (ID: 1369)
        ├── UsersEvent (ID: 161)
        └── ObjectsMessageEvent (ID: 1778)
```

### Chat Communication

```
[Out] ChatMessageComposer (ID: 2900)
        │
        ▼
[In] ChatMessageEvent (ID: 1446)
        │
        └── ChatMessageEvent (whisper, shout variants)
```

### Ping/Pong (Keep-Alive)

```
[In] PingMessageEvent (ID: 4607)
        │
        ▼
[Out] PongMessageComposer (ID: 4607)
```

## Error Handling

### Error Types

| Event | Cause |
|-------|-------|
| IOErrorEvent.IO_ERROR | Network connectivity |
| IOErrorEvent.NETWORK_ERROR | Network layer error |
| SecurityErrorEvent | SSL/policy violations |
| Timeout | No server response |

### Port Retry Logic

```
tryNextPort()
        │
        ├── If current port fails:
        │       ├── Increment _portIndex
        │       └── If ports exhausted:
        │               ├── Increment _connectionAttempts
        │               └── If attempts <= max (2):
        │                       └── Reset port index
        │
        └── Create new socket, attempt connection
```

### Disconnection Handling

```
onConnectionDisconnected()
        │
        ├── If handshake in progress: dispatch HANDSHAKE_FAIL
        ├── If ExternalInterface: call logDisconnection()
        └── If !logoutInProgress: navigate to disconnect page
```

## Message Queue During Auth

```
If !_authenticated OR !_configurationReady
        │
        ├── Outgoing messages queued in _pendingClientMessages
        ├── Incoming messages queued in _pendingServerMessages
        │
        └── When authenticated/configured:
                └── Process all pending messages
```

## Architecture Diagram

```
┌────────────────────────────────────────────┐
│           APPLICATION LAYER                │
│  (UI Components, Widgets, Managers)        │
└──────────────────────┬─────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────┐
│          HANDLER REGISTRATION              │
│  addHabboConnectionMessageEvent(new       │
│    MessageEvent(callback))                │
└──────────────────────┬─────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────┐
│        MESSAGE CLASS MANAGER               │
│  - Maps Message ID <-> Event/Composer     │
│  - Routes messages to handlers            │
└──────────────────────┬─────────────────────┘
          ┌───────────┴───────────┐
          ▼                       ▼
┌──────────────────┐    ┌──────────────────────┐
│  OUTGOING       │    │    INCOMING          │
│                  │    │                      │
│ Composer         │    │ Socket Data          │
│     │            │    │     │                │
│     ▼            │    │     ▼                │
│ getMessageArray  │    │ decode()             │
│     │            │    │     │                │
│     ▼            │    │     ▼                │
│ encode()         │    │ decipher()           │
│     │            │    │     │                │
│     ▼            │    │     ▼                │
│ encipher()       │    │ parse()              │
│     │            │    │     │                │
│     ▼            │    │     ▼                │
│ Socket.write()   │    │ callback -> UI       │
└──────────────────┘    └──────────────────────┘
          │                       │
          └───────────┬───────────┘
                      ▼
┌────────────────────────────────────────────┐
│           SOCKET CONNECTION                │
│  - Flash Socket (TCP)                      │
│  - Event dispatching                       │
│  - Encryption management                    │
└──────────────────────┬─────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│            NETWORK (TCP/IP)               │
└────────────────────────────────────────────┘
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `HabboCommunicationManager.as` | Main manager, connection handling |
| `SocketConnection.as` | TCP socket wrapper |
| `HabboMessages.as` | Message ID mappings |
| `MessageClassManager.as` | Message routing |
| `EvaWireFormat.as` | Binary encoding |
| `ArcFour.as` | RC4 encryption |
| `DiffieHellman.as` | Key exchange |
| `HabboCommunicationDemo.as` | Handshake handling |