# Room Interactions

This document details the data flow for room entry, object creation, state updates, and room exit.

## Room Interaction Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ROOM INTERACTION FLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ROOM ENTRY                                  │   │
│  │                                                                       │   │
│  │  GoToFlatMessageComposer ──► OpenConnectionEvent                    │   │
│  │         │                             │                              │   │
│  │         ▼                             ▼                              │   │
│  │  RoomSessionManager            RoomReadyMessageEvent                  │   │
│  │         │                             │                              │   │
│  │         ▼                             ▼                              │   │
│  │  RoomSession                  FloorHeightMapEvent                    │   │
│  │         │                             │                              │   │
│  │         ▼                             ▼                              │   │
│  │  RoomEngine                   RoomPropertyMessageEvent              │   │
│  │                                    │                                  │   │
│  │                                    ▼                                  │   │
│  │                           RoomEngine.initializeRoom()                 │   │
│  │                                    │                                  │   │
│  │                                    ▼                                  │   │
│  │                           RoomInstance + Canvas                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    OBJECT CREATION / UPDATES                         │   │
│  │                                                                       │   │
│  │  ObjectsMessageEvent ──► addActiveObject ──► createRoomObject        │   │
│  │  UsersEvent           ──► addObjectUser   ──► createRoomObject       │   │
│  │  ItemAddMessageEvent  ──► addWallItem    ──► createRoomObject        │   │
│  │                                                                       │   │
│  │  ObjectUpdateMessageEvent ──► updateObjectFurniture ──► Renderer      │   │
│  │  UserUpdateEvent          ──► updateObjectUser      ──► Renderer    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ROOM EXIT                                    │   │
│  │                                                                       │   │
│  │  CloseConnectionMessageEvent ──► sessionUpdate(RS_DISCONNECTED)      │   │
│  │         │                             │                              │   │
│  │         ▼                             ▼                              │   │
│  │  RoomSessionManager.disposeSession()                                 │   │
│  │         │                                                              │   │
│  │         ▼                                                              │   │
│  │  RoomEngine.disposeRoom() ──► RoomManager.disposeRoom()             │   │
│  │         │                                                              │   │
│  │         ▼                                                              │   │
│  │  Canvas cleanup ──► Renderer disposed                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Room Entry Flow

### Initiation

```
User clicks room
        │
        ▼
RoomSessionManager.gotoRoom(roomId)
        │
        ▼
RoomSessionHandler sends:
    GoToFlatMessageComposer(roomId)
        │
        ▼
Server responds with:
    OpenConnectionMessageEvent
```

### Session Connection

```
OpenConnectionMessageEvent
        │
        ├── listener.sessionUpdate(roomId, RS_CONNECTED)
        │
        ▼
RoomSessionManager creates RoomSession
        │
        ▼
FlatAccessibleMessageEvent
        │
        ▼
Sends another GoToFlatMessageComposer
        │
        ▼
RoomReadyMessageEvent
        │
        ├── sessionReinitialize()
        └── sessionUpdate(RS_READY)
```

### Room Initialization Sequence

```
RoomReadyMessageEvent
        │
        ├── setCurrentRoom(roomId)
        ├── setWorldType()
        └── Requests room entry data:
            ├── First time: GetFurnitureAliasesMessageComposer
            └── Re-entry: GetRoomEntryDataMessageComposer
        │
        ▼
FloorHeightMapEvent
        │
        ├── Parses height map data
        ├── Creates FurniStackingHeightMap
        └── Stores in room
        │
        ▼
RoomPropertyMessageEvent
        │
        ├── Parses floor/wall/landscape types
        ├── Creates RoomPlaneParser XML
        └── Calls _roomCreator.initializeRoom()
```

### Room Instance Creation

```
RoomEngine.initializeRoom(k, xml)
        │
        ├── Creates RoomData with settings
        │
        ├── _roomManager.createRoom(identifier, xml)
        │       │
        │       ├── Creates RoomInstance
        │       ├── Creates room object (OBJECT_ID_ROOM = -1)
        │       ├── Sets room variables (ROOM_MIN_X, etc.)
        │       ├── Initializes room event handler
        │       └── Creates cursor/highlighter objects
        │
        └── Dispatches RoomEngineEvent.INITIALIZED
```

### Canvas Creation

```
RoomDesktop creates room canvas:
        │
        ├── _roomEngine.createRoomCanvas(session.roomId, canvasId, ...)
        │
        └── Inside RoomEngine:
                ├── Gets IRoomInstance from RoomManager
                ├── Creates IRoomRenderer
                ├── Creates IRoomRenderingCanvas
                └── Returns DisplayObject for embedding
```

## Object Creation Flow

### Furniture Objects

```
ObjectsMessageEvent (initial batch)
        │
        ├── Parses ObjectsMessageParser
        └── For each object: addActiveObject()

addActiveObject():
        ├── Creates Vector3d for position
        ├── Creates Vector3d for direction
        └── Calls _roomCreator.addObjectFurniture()

RoomEngine.addObjectFurniture():
        ├── Creates FurnitureData
        ├── Adds to RoomInstanceData
        └── Returns (queued for creation)

addObjectFurnitureFromData():
        ├── Gets FurnitureData
        ├── Creates IRoomObjectController via createRoomObject()
        ├── Sets model variables (FURNITURE_COLOR, etc.)
        └── Dispatches RoomEngineObjectEvent.ADDED
```

### User/Avatar Objects

```
UsersEvent (initial batch)
        │
        ├── _roomCreator.addObjectUser()
        ├── If own user: setOwnUserId() + updateObjectUserOwnUserAvatar()
        ├── updateObjectUserFigure() - sets appearance
        └── If pet: updateObjectUserPosture()
```

### Wall Items

```
ItemsEvent / ItemAddMessageEvent
        │
        ├── Uses LegacyWallGeometry to convert wall coordinates
        └── Calls _roomCreator.addObjectWallItem()
```

## Update Cycle

### Furniture Updates

```
ObjectUpdateMessageEvent
        │
        ├── Receives ObjectMessageData
        ├── Creates position/direction vectors
        └── Calls:
                ├── updateObjectFurniture(position, direction, state, data)
                └── updateObjectFurnitureHeight(sizeZ)

ObjectDataUpdateMessageEvent
        └── Updates furniture state/data without position change

ObjectRemoveMessageEvent
        ├── Parses object ID and picker ID
        └── Calls _roomCreator.disposeObjectFurniture()
```

### User Movement Updates

```
UserUpdateEvent (continuous movement)
        │
        ├── Parses multiple users
        ├── For each user: gets IRoomObject
        └── Creates update message with new position/steps
```

### Avatar Action Updates

| Event | Update Message |
|-------|---------------|
| ExpressionMessageEvent | RoomObjectExpressionUpdateMessage |
| DanceMessageEvent | RoomObjectAvatarDanceUpdateMessage |
| SleepMessageEvent | RoomObjectAvatarSleepUpdateMessage |
| CarryObjectMessageEvent | RoomObjectAvatarCarryObjectUpdateMessage |
| UseObjectMessageEvent | RoomObjectAvatarUseObjectUpdateMessage |

### Render Cycle

```
Update Loop (via IUpdateReceiver)
        │
        ├── RoomRenderer.update(geometry, time, ...)
        ├── For each visible room object:
        │       ├── IRoomObjectVisualization.update() - updates sprites
        │       └── RoomObjectCache processes updates
        │
        └── RoomSpriteCanvas.render() - draws to BitmapData
```

## Room Exit Flow

### Session Disconnection

```
CloseConnectionMessageEvent
        │
        ├── Clears ErrorReportStorage room data
        └── listener.sessionUpdate(roomId, RS_DISCONNECTED)
```

### Session Cleanup

```
sessionUpdate(RS_DISCONNECTED)
        │
        └── disposeSession(roomId)
                │
                ├── Removes RoomSession from Map
                ├── Dispatches RoomSessionEvent.ENDED
                └── Calls RoomSession.dispose()
```

### Room Engine Cleanup

```
RoomEngine.disposeRoom(roomId):
        │
        ├── _roomManager.disposeRoom(identifier)
        │       ├── Disposes all room objects
        │       ├── Disposes renderer
        │       └── Removes from Map
        │
        ├── Removes RoomInstanceData
        └── Dispatches RoomEngineEvent.DISPOSED
```

### Canvas Cleanup

```
When RoomDesktop disposes:
        │
        ├── Disposes all widgets
        ├── Disposes layout manager
        ├── Removes canvas wrapper from display
        └── Cleans up event listeners
```

## Data Flow Summary Diagram

```
                                    SERVER
                                       │
          ┌────────────────────────────┼────────────────────────────┐
          │                            │                            │
     GoToFlat                   RoomReady                   Objects
  MessageEvent               MessageEvent               MessageEvent
          │                            │                            │
          ▼                            ▼                            ▼
   +-----------------+    +-------------------+    +------------------+
   │ RoomSessionMgr  │    │ RoomMessageHandler│    │   RoomEngine    │
   │                 │    │                   │    │                 │
   │  RoomSession    │    │  initializeRoom   │    │ createRoom      │
   └────────┬────────┘    └─────────┬─────────┘    └────────┬─────────┘
            │                       │                       │
            ▼                       ▼                       ▼
     RoomEngine            RoomInstance              RoomObjectManager
            │                       │                       │
            └──────────────────────┼───────────────────────┘
                                     │
                                     ▼
                              RoomRenderer
                               (Canvas)
                                     │
                                     ▼
                                UI Display
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `RoomSessionHandler.as` | Session handling |
| `RoomMessageHandler.as` | Room message processing |
| `RoomEngine.as` | Room creation/update |
| `RoomSessionManager.as` | Session management |
| `RoomSpriteCanvas.as` | Rendering |