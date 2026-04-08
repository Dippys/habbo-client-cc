# Room Object Lifecycle

Room objects represent everything visible in a room: furniture, avatars, pets, wall items, and the room itself. This document details how objects are created, managed, updated, and disposed.

## Lifecycle Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ROOM OBJECT LIFECYCLE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────┐                                                           │
│   │  CREATED    │  RoomEngine.createRoomObject()                            │
│   └──────┬──────┘                                                           │
│          │                                                                   │
│          ▼                                                                   │
│   ┌─────────────┐     ┌─────────────┐                                       │
│   │ INITIALIZED │ ──► │   LOGIC     │  RoomObjectLogicComponent             │
│   │             │     │ ATTACHED    │  creates handler                      │
│   └──────┬──────┘     └──────┬──────┘                                       │
│          │                   │                                               │
│          ▼                   ▼                                               │
│   ┌─────────────────────────────────────────────────────┐                   │
│   │                   RUNTIME                          │                   │
│   │                                                      │                   │
│   │  - Update loop (every frame)                        │                   │
│   │  - State changes (location, direction, states)      │                   │
│   │  - Mouse interaction                                │                   │
│   │  - Model variable updates                          │                   │
│   │                                                      │                   │
│   └──────────────────────┬──────────────────────────────┘                   │
│                          │                                                  │
│                          ▼                                                  │
│   ┌─────────────┐     ┌─────────────┐                                        │
│   │  TEARDOWN   │ ──► │  DISPOSED   │  tearDown() -> dispose()              │
│   │             │     │             │                                        │
│   └─────────────┘     └─────────────┘                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Object Creation Flow

### Step-by-Step Creation

```
1. RoomEngine.createRoomObject(roomId, objectId, type, category)
   │
   ▼
2. RoomInstance.createRoomObject(objectId, type, category)
   │
   ▼
3. RoomManager.createRoomObject(roomId, objectId, type, category)
   │
   ▼
4. RoomInstance.createObjectInternal(objectId, category, type)
   │
   ▼
5. RoomObjectManager.createObject(objectId, stateCount, type)
   │
   ▼
6. new RoomObject(objectId, stateCount, type)
   │
   ▼
7. Add to manager maps (_objects, _objectsPerType)
```

### Creation Code Flow

```actionscript
// RoomEngine.as
public function createRoomObject(roomId:int, objectId:int, type:String, category:int):IRoomObject
{
    var room:IRoomInstance = _roomManager.getRoom(roomId);
    return room.createRoomObject(objectId, type, category);
}

// RoomInstance.as
public function createRoomObject(k:int, _arg_2:String, _arg_3:int):IRoomObject
{
    var manager:IRoomObjectManager = this.getObjectManager(_arg_3);
    return manager.createObject(k, 0, _arg_2);
}

// RoomObjectManager.as
public function createObject(k:int, _arg_2:uint, _arg_3:String):IRoomObjectController
{
    var roomObject:RoomObject = new RoomObject(k, _arg_2, _arg_3);
    return this.addObject(String(k), _arg_3, roomObject);
}
```

## RoomObject Class Structure

### File: `src/com/sulake/room/object/RoomObject.as`

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `_id` | int | Unique object ID within the room |
| `_type` | String | Object type (e.g., "furniture_basic", "user") |
| `_loc` | Vector3D | Internal position (x, y, z) |
| `_dir` | Vector3D | Direction/rotation |
| `_stateList` | Array | Object state values |
| `_roomObjectModel` | RoomObjectModel | Data container |
| `_visualization` | IRoomObjectVisualization | Rendering component |
| `_roomObjectLogic` | IRoomObjectEventHandler | Logic handler |
| `_updateID` | int | Change counter |

### Constructor

```actionscript
public function RoomObject(k:int, _arg_2:int, _arg_3:String)
{
    this._id = k;
    this._stateList = new Array(_arg_2);
    this._type = _arg_3;
    
    this._loc = new Vector3D();
    this._dir = new Vector3D();
    this._locVisible = new Vector3D();
    this._dirVisible = new Vector3D();
    
    this._roomObjectModel = new RoomObjectModel(this);
    this._updateID = 0;
}
```

## State Management

### Location

```actionscript
public function setLocation(k:IVector3d):void
{
    if (k == null) return;
    if ((((!(this._loc.x == k.x)) || (!(this._loc.y == k.y))) || (!(this._loc.z == k.z))))
    {
        this._loc.x = k.x;
        this._loc.y = k.y;
        this._loc.z = k.z;
        this._updateID++;
    }
}

public function getLocation():IVector3d
{
    this._locVisible.assign(this._loc);
    return this._locVisible;
}
```

### Direction

```actionscript
public function setDirection(k:IVector3d):void
{
    if (k == null) return;
    this._dir.x = (((k.x % 360) + 360) % 360);
    this._dir.y = (((k.y % 360) + 360) % 360);
    this._dir.z = (((k.z % 360) + 360) % 360);
    this._updateID++;
}
```

### State Values

```actionscript
public function setState(k:int, _arg_2:int):Boolean
{
    if ((_arg_2 >= 0) && (_arg_2 < this._stateList.length))
    {
        if (this._stateList[_arg_2] != k)
        {
            this._stateList[_arg_2] = k;
            this._updateID++;
        }
        return true;
    }
    return false;
}

public function getState(k:int):int
{
    if (((k >= 0) && (k < this._stateList.length)))
    {
        return this._stateList[k];
    }
    return -1;
}
```

## Logic Attachment

### RoomObjectLogicComponent
**File:** `src/com/sulake/habbo/room/RoomObjectLogicComponent.as`

Creates appropriate logic handler based on object type:

```actionscript
public function createRoomObjectLogic(logicKey:String):IRoomObjectEventHandler
{
    switch (logicKey)
    {
        case "FURNITURE_BASIC":
            return new FurnitureLogic();
        case "FURNITURE_MULTISTATE":
            return new FurnitureMultistateLogic();
        case "USER":
        case "BOT":
            return new AvatarLogic();
        case "PET":
            return new PetLogic();
        case "FURNITURE_DICE":
            return new FurnitureDiceLogic();
        // ... 80+ more types
    }
}
```

### Logic Base Class
**File:** `src/com/sulake/room/object/logic/ObjectLogicBase.as`

```actionscript
public class ObjectLogicBase implements IRoomObjectEventHandler 
{
    protected var _object:IRoomObjectController;
    protected var _events:IEventDispatcher;
    
    // Called each frame
    public function update(k:int):void { }
    
    // Handle server updates
    public function processUpdateMessage(k:RoomObjectUpdateMessage):void { }
    
    // Handle mouse events
    public function mouseEvent(k:RoomSpriteMouseEvent, _arg_2:IRoomGeometry):void { }
    
    // Cleanup on dispose
    public function tearDown():void { }
}
```

## Object Model Variables

### RoomObjectVariableEnum
**File:** `src/com/sulake/habbo/room/object/RoomObjectVariableEnum.as`

Key variables used to store object data:

### Avatar Variables

| Variable | Type | Description |
|----------|------|-------------|
| `FIGURE` | String | Avatar figure string |
| `FIGURE_GESTURE` | String | Current gesture |
| `FIGURE_POSTURE` | String | Current posture |
| `FIGURE_EXPRESSION` | String | Facial expression |
| `FIGURE_EFFECT` | int | Active effect ID |
| `FIGURE_IS_TYPING` | Boolean | Typing state |
| `GENDER` | String | Gender (M/F) |
| `RACE` | int | Pet race ID |

### Furniture Variables

| Variable | Type | Description |
|----------|------|-------------|
| `FURNITURE_TYPE_ID` | int | Furniture type |
| `FURNITURE_SIZE_X` | Number | Width in tiles |
| `FURNITURE_SIZE_Y` | Number | Depth in tiles |
| `FURNITURE_SIZE_Z` | Number | Height |
| `FURNITURE_OWNER_ID` | int | Owner user ID |
| `FURNITURE_OWNER_NAME` | String | Owner name |
| `FURNITURE_EXTRAS` | String | Extra data string |
| `FURNITURE_CUSTOM_VARIABLES` | Array | Custom variables |

### Room Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ROOM_FLOOR_TYPE` | String | Floor texture |
| `ROOM_WALL_TYPE` | String | Wall texture |
| `ROOM_LANDSCAPE_TYPE` | String | Landscape texture |
| `ROOM_BACKGROUND_COLOR` | int | Background color |

### Using Variables

```actionscript
// Setting
object.getModelController().setNumber(RoomObjectVariableEnum.FURNITURE_TYPE_ID, 1234);
object.getModelController().setString(RoomObjectVariableEnum.FURNITURE_OWNER_NAME, "Username");

// Getting
var typeId:int = object.getModel().getNumber(RoomObjectVariableEnum.FURNITURE_TYPE_ID);
```

## Disposal Flow

### Complete Disposal Sequence

```
1. RoomInstance.disposeObject(objectId, category)
   │
   ▼
2. Get object from manager
   │
   ▼
3. Call object.tearDown()
   │   └── Calls logic.tearDown()
   │
   ▼
4. Remove from renderer
   │
   ▼
5. Call manager.disposeObject(objectId)
   │   └── Removes from maps
   │   └── Calls object.dispose()
   │
   ▼
6. RoomObject.dispose()
       └── Disposes visualization
       └── Disposes event handler
       └── Disposes model
```

### tearDown() Method

```actionscript
public function tearDown():void
{
    if (this._roomObjectLogic)
    {
        this._roomObjectLogic.tearDown();
    }
}
```

### dispose() Method

```actionscript
public function dispose():void
{
    this._loc = null;
    this._dir = null;
    this._stateList = null;
    
    // Dispose visualization
    if (this._visualization != null)
    {
        this._visualization.dispose();
        this._visualization = null;
    }
    
    // Dispose logic handler
    this.setEventHandler(null);
    
    // Dispose model
    if (this._roomObjectModel != null)
    {
        this._roomObjectModel.dispose();
        this._roomObjectModel = null;
    }
}
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/room/object/RoomObject.as` | Base object class |
| `src/com/sulake/room/object/logic/ObjectLogicBase.as` | Base logic class |
| `src/com/sulake/habbo/room/RoomObjectLogicComponent.as` | Logic factory |
| `src/com/sulake/habbo/room/object/RoomObjectVariableEnum.as` | Variable definitions |
| `src/com/sulake/room/RoomObjectManager.as` | Object tracking |
| `src/com/sulake/room/RoomInstance.as` | Room-level object management |

## Next Steps

- [Room Rendering](Core-Systems/Room-Engine/Rendering) - Render pipeline
- [Furniture System Architecture](Core-Systems/Furniture-System/Architecture) - Furniture logic
