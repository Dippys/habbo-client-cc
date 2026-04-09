# Furniture Interactions

This document details the data flow from user interaction with furniture through server response and visual updates.

## Furniture Interaction Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FURNITURE INTERACTION FLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      MOUSE INTERACTION                               │   │
│  │                                                                       │   │
│  │  Room Canvas Mouse Event                                           │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  RoomObjectEventHandler.handleRoomObjectEvent()                      │   │
│  │         │                                                             │   │
│  │    ┌─────┴─────┬─────────────┐                                        │   │
│  │    ▼           ▼             ▼                                        │   │
│  │  Tile       Avatar        Furniture                                   │   │
│  │  Click      Click          Click                                       │   │
│  │    │           │             │                                         │   │
│  │    ▼           ▼             ▼                                         │   │
│  │  walkTo()   [game logic]   IRoomObject.getEventHandler()              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      DOUBLE-CLICK → USE                             │   │
│  │                                                                       │   │
│  │  FurnitureLogic.mouseEvent(DOUBLE_CLICK)                            │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  useObject()                                                         │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  dispatch RoomObjectWidgetRequestEvent(OPEN_WIDGET)                 │   │
│  │  dispatch RoomObjectStateChangedEvent(STATE_CHANGE)                  │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  UseFurnitureMessageComposer(objectId, param)                       │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  Connection.send()                                                   │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SERVER RESPONSE → UPDATE                         │   │
│  │                                                                       │   │
│  │  Server: ObjectUpdateMessageEvent                                    │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  RoomMessageHandler.onObjectUpdate()                                 │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  _roomCreator.updateObjectFurniture()                                │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  IRoomObject.setPosition() + getModel().setX()                       │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  FurnitureVisualization.update() → sprites update                     │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Mouse Interaction

### Room Canvas to Logic

```
Room Rendering Canvas
        │
        ▼ (Mouse Event: RoomObjectMouseEvent)
        │
RoomObjectEventHandler.handleRoomObjectEvent()
        │
        ├── handleClickOnTile()    [Floor clicks]
        │       └── walkTo() -> MoveAvatarMessageComposer
        │
        ├── handleClickOnAvatar()  [Avatar clicks]
        │       └── gameEngine._SafeStr_7623()
        │
        └── IRoomObject.getEventHandler() [Furniture]
```

### Object Category Handling

| Category | Handler | Action |
|----------|---------|--------|
| TILE | `handleClickOnTile()` | Walk to position |
| USER | `handleClickOnAvatar()` | Avatar interaction |
| FURNITURE | `getEventHandler()` | Furniture logic |
| WALL_ITEM | `getEventHandler()` | Wall item logic |

## Double-Click to Use

### Client-Side Flow

```
FurnitureLogic.mouseEvent(DOUBLE_CLICK)
        │
        └── useObject()
                │
                ├── dispatch OPEN_WIDGET event
                └── dispatch STATE_CHANGE event
```

### Server Communication

```
UseFurnitureMessageComposer(objectId, param)
        │
        └── Message payload: [objectId, param]
        │
        └── Server processes action
```

### Related Composers

| Composer | Purpose |
|----------|---------|
| `UseFurnitureMessageComposer` | Use furniture |
| `SetRandomStateMessageComposer` | Random state items |
| `ThrowDiceMessageComposer` | Dice throw |
| `DiceOffMessageComposer` | Dice reset |
| `SpinWheelOfFortuneMessageComposer` | Wheel of Fortune |

## Server Response Flow

### ObjectUpdateMessageEvent

```
SERVER: ObjectUpdateMessageEvent (ID: 3776)
        │
        ▼
RoomMessageHandler.onObjectUpdate()
        │
        ├── Parses ObjectUpdateMessageParser
        │       - id, x, y, z, dir, state, data, extra, sizeZ, expiryTime
        │
        ▼
_roomCreator.updateObjectFurniture()
        │
        ├── Updates position/direction
        ├── Sets model variables (FURNITURE_COLOR, etc.)
        └── Triggers visualization update
        │
        ▼
FurnitureVisualization.update()
        │
        └── Sprites re-render with new state
```

### State Update Sequence

```
User Double-Click
        │
        ▼
UseFurnitureMessageComposer [outgoing]
        │
        ▼
Server processes action
        │
        ▼
ObjectUpdateMessageEvent [incoming]
        │
        ▼
RoomMessageHandler.onObjectUpdate()
        │
        ▼
_roomCreator.updateObjectFurniture() -> IRoomObject.setPosition/setModel()
        │
        ▼
Furniture visualization re-renders (via update loop)
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `RoomObjectEventHandler.as` | Mouse event routing |
| `FurnitureLogic.as` | Furniture logic handling |
| `UseFurnitureMessageComposer.as` | Server message |
| `RoomMessageHandler.as` | Server message processing |
| `FurnitureVisualization.as` | Visual rendering |