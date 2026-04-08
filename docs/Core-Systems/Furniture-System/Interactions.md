# Furniture Interactions

The Furniture Interactions system handles how users interact with room objects - from single-click context menus to double-click usage that opens widgets. This document details the complete interaction flow.

## Interaction Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     FURNITURE INTERACTION FLOW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  User Double-Click on Furniture                                             │
│           │                                                                   │
│           ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │                   FurnitureLogic.mouseEvent()                        │     │
│  │                                                                       │     │
│  │  DOUBLE_CLICK ──► useObject()                                        │     │
│  │       │                                                               │     │
│  │  CLICK ──► dispatch OPEN_FURNI_CONTEXT_MENU                         │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
│           │                                                                   │
│           │                    ┌────────────────────────────────────────┐   │
│           ▼                    │                                        │   │
│  ┌──────────────────┐          ▼                                        │   │
│  │ Widget Request  │          │ Context Menu Request                  │   │
│  │                 │          │                                        │   │
│  │ OPEN_WIDGET    │          │ OPEN_FURNI_CONTEXT_MENU                 │   │
│  │ STATE_CHANGE   │          │                                        │   │
│  └────────┬─────────┘          └──────────────────┬─────────────────────┘   │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌──────────────────┐          ┌──────────────────────────────────────┐    │
│  │ RoomObjectEvent │          │ RoomObjectEventHandler                │    │
│  │ Handler         │          │                                      │    │
│  │                 │          │ Converts to:                         │    │
│  │ Converts to:    │          │ RETWE_OPEN_FURNI_CONTEXT_MENU         │    │
│  │ RETWE_OPEN_     │          │                                      │    │
│  │   WIDGET        │          │                                      │    │
│  └────────┬─────────┘          └──────────────────┬───────────────────┘    │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    Widget Handlers                                   │    │
│  │                                                                       │    │
│  │  FurnitureDimmerWidgetHandler  │ FurnitureStickieWidgetHandler     │    │
│  │  FurniturePresentWidgetHandler│ InfoStandWidgetHandler            │    │
│  │  FurnitureContextMenuHandler  │ (and more)                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │               Server Communication                                   │    │
│  │                                                                       │    │
│  │  UseFurnitureMessageComposer   │ RoomSession methods               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Mouse Event Handling

### FurnitureLogic.mouseEvent()
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureLogic.as`

### Event Types

| Event | Action |
|-------|--------|
| `MOUSE_MOVE` | Highlight detection |
| `ROLL_OVER` | Show tooltip |
| `ROLL_OUT` | Hide tooltip |
| `CLICK` | Open context menu |
| `DOUBLE_CLICK` | Use object |
| `MOUSE_DOWN` | Start drag (placement) |

### Single Click - Context Menu

```actionscript
case MouseEvent.CLICK:
    if (contextMenu != null)
    {
        eventDispatcher.dispatchEvent(new RoomObjectWidgetRequestEvent(
            RoomObjectWidgetRequestEvent.OPEN_FURNI_CONTEXT_MENU, object));
    }
```

### Double Click - Use Object

```actionscript
override public function useObject():void
{
    // Open widget if assigned
    if (widget != null)
    {
        eventDispatcher.dispatchEvent(new RoomObjectWidgetRequestEvent(
            RoomObjectWidgetRequestEvent.OPEN_WIDGET, object));
    }
    
    // Trigger state change
    eventDispatcher.dispatchEvent(new RoomObjectStateChangedEvent(
        RoomObjectStateChangedEvent.STATE_CHANGE, object));
}
```

## Server Communication

### UseFurnitureMessageComposer
**File:** `src/com/sulake/habbo/communication/messages/outgoing/room/engine/UseFurnitureMessageComposer.as`

```actionscript
public class UseFurnitureMessageComposer implements IMessageComposer
{
    private var _objectId:int;
    private var _param:int = 0;  // Multi-state parameter
    
    public function UseFurnitureMessageComposer(k:int, _arg_2:int = 0)
    {
        this._objectId = k;
        this._param = _arg_2;
    }
    
    public function getMessageArray():Array
    {
        return [this._objectId, this._param];
    }
}
```

### Message Flow

```actionscript
// In usage handler
connection.send(new UseFurnitureMessageComposer(objectId, param));

// Server processes, responds with ObjectUpdateMessageComposer
// Client updates state via FurnitureLogic._Str_9796()
```

## Widget System

### Widget Request Events

**File:** `src/com/sulake/habbo/room/events/RoomObjectWidgetRequestEvent.as`

| Event | Widget Type |
|-------|-------------|
| `OPEN_WIDGET` | Generic furniture widget |
| `OPEN_FURNI_CONTEXT_MENU` | Context menu |
| `DIMMER` | Room dimmer |
| `STICKIE` | Stickie note |
| `PRESENT` | Gift present |
| `TROPHY` | Trophy display |

### Widget Handlers

| Handler | Furniture Type |
|---------|----------------|
| `FurnitureDimmerWidgetHandler` | Room dimmer |
| `FurnitureStickieWidgetHandler` | Stickie notes |
| `FurniturePresentWidgetHandler` | Gift presents |
| `FurnitureTrophyWidgetHandler` | Trophies |
| `FurnitureClothingChangeWidgetHandler` | Mannequins |
| `MannequinWidgetHandler` | Mannequins |
| `InfoStandWidgetHandler` | Generic furniture info |

### Dimmer Widget Example

```actionscript
// FurnitureDimmerWidgetHandler.as
public function processWidgetMessage(k:RoomWidgetMessage):RoomWidgetUpdateEvent
{
    switch (k.type)
    {
        case RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_DIMMER:
            // Request dimmer presets from server
            this._container.roomSession.sendRoomDimmerGetPresetsMessage();
            break;
            
        case RoomWidgetDimmerSavePresetMessage.RWSDPM_SAVE_PRESET:
            // Save new preset
            this._container.roomSession.sendRoomDimmerSavePresetMessage(
                presetId, effectId, color, brightness, apply);
            break;
    }
}
```

### Stickie Widget Example

```actionscript
// FurnitureStickieWidgetHandler.as
public function processWidgetMessage(k:RoomWidgetMessage):RoomWidgetUpdateEvent
{
    switch (k.type)
    {
        case RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_STICKIE:
            // Load stickie data from model
            var stickieData:String = object.getModel().getString(
                RoomObjectVariableEnum.FURNITURE_ITEMDATA);
            break;
            
        case RoomWidgetStickieSendUpdateMessage.RWSUM_STICKIE_SEND_UPDATE:
            // Update stickie content
            this._container.roomEngine.modifyRoomObjectData(
                objectId, OBJECT_CATEGORY_WALLITEM, data, text);
            break;
    }
}
```

## Context Menu

### FurnitureContextMenuWidgetHandler
**File:** `src/com/sulake/habbo/ui/handler/FurnitureContextMenuWidgetHandler.as`

### Context Menu Types

| Type | Furniture |
|------|-----------|
| `FRIEND_FURNITURE` | Friend's furniture |
| `MONSTERPLANT_SEED` | Monster plant |
| `MYSTERY_BOX` | Mystery box |
| `RANDOM_TELEPORT` | Teleport |
| `PURCHASABLE_CLOTHING` | Clothing |

### Handler Flow

```actionscript
// Processing context menu event
switch (_local_2.contextMenu)
{
    case ContextMenuEnum.FRIEND_FURNITURE:
        this._widget._Str_25158(_local_3);  // Show friend options
        break;
    case ContextMenuEnum.MONSTERPLANT_SEED:
        this._widget._Str_23088(_local_3, _local_2.category);
        break;
}
```

## Info Stand

### InfoStandWidgetHandler
**File:** `src/com/sulake/habbo/ui/handler/InfoStandWidgetHandler.as`

Handles basic furniture actions:

### Messages Processed

| Message | Action |
|---------|--------|
| `RWFAM_MOVE` | Move furniture |
| `RWFUAM_ROTATE` | Rotate furniture |
| `RWFAM_PICKUP` | Pick up to inventory |
| `RWFAM_EJECT` | Remove from room |
| `RWFAM_USE` | Use furniture |
| `RWFAM_SAVE_STUFF_DATA` | Save custom data |

### Info Retrieval

```actionscript
private function handleGetFurniInfoMessage(k:RoomWidgetRoomObjectMessage):void
{
    // Get furniture data
    var furnitureData:IFurnitureData = sessionDataManager.getFloorItemData(typeId);
    
    // Get owner info from model
    var ownerId:int = model.getNumber(FURNITURE_OWNER_ID);
    var ownerName:String = model.getString(FURNITURE_OWNER_NAME);
    
    // Dispatch to UI
    events.dispatchEvent(new RoomWidgetFurniInfoUpdateEvent(...));
}
```

## State Change Handling

### ObjectUpdateMessageComposer Response

When server processes use action:

```
Server: ObjectUpdateMessageComposer(itemId, newState, data)
    │
    ▼
RoomMessageHandler.onObjectUpdate()
    │
    ▼
FurnitureLogic._Str_9796(k)
    │
    ▼
object.setState(k.state, 0)
model.setString(FURNITURE_ITEMDATA, k.data)
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureLogic.as` | Mouse handling, useObject |
| `src/com/sulake/habbo/communication/messages/outgoing/room/engine/UseFurnitureMessageComposer.as` | Server message |
| `src/com/sulake/habbo/room/events/RoomObjectWidgetRequestEvent.as` | Widget events |
| `src/com/sulake/habbo/ui/handler/FurnitureContextMenuWidgetHandler.as` | Context menu |
| `src/com/sulake/habbo/ui/handler/InfoStandWidgetHandler.as` | Info/actions |
| `src/com/sulake/habbo/ui/handler/FurnitureDimmerWidgetHandler.as` | Dimmer widget |
| `src/com/sulake/habbo/ui/handler/FurnitureStickieWidgetHandler.as` | Stickie widget |

## Next Steps

- [Furniture Types](Core-Systems/Furniture-System/Types) - Specialized furniture categories