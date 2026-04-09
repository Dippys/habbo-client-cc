# Widget System

The Widget System provides UI elements for room-based interactions, bridging the window system with Habbo-specific functionality like furniture widgets, chat, and information displays.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WIDGET SYSTEM ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     RoomWidgetFactory                                │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ RoomChatWidget  │  │ FurnitureDimmer  │  │ FurnitureStickie│   │   │
│  │  │                 │  │    Widget        │  │    Widget       │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  (40+ widget types)                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Widget Handlers                                   │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ FurnitureDimmer │  │ FurnitureStickie │  │ ChatWidgetHandler│   │   │
│  │  │  Handler         │  │    Handler        │  │                 │   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - Messages      │  │ - Messages       │  │ - Events        │   │   │
│  │  │ - Events        │  │ - Events         │  │ - Messages      │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  IRoomWidgetHandlerContainer                                         │   │
│  │  - roomSession, roomEngine, events, windowManager, etc.                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   RoomWidgetMessage                                  │   │
│  │                                                                       │   │
│  │  WidgetMessage -> Handler -> RoomEngine/Server                       │   │
│  │       │                                                               │   │
│  │       ▼                                                               │   │
│  │  RoomEvent -> Handler -> WidgetUpdateEvent -> Widget                 │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Interfaces

### IRoomWidget
**File:** `src/com/sulake/habbo/ui/widget/IRoomWidget.as`

Base interface for all room widgets:

```actionscript
public interface IRoomWidget 
{
    function get state():int;
    function initialize(_arg_1:int=0):void;
    function dispose():void;
    function set messageListener(_arg_1:IRoomWidgetMessageListener):void;
    function registerUpdateEvents(_arg_1:IEventDispatcher):void;
    function unregisterUpdateEvents(_arg_1:IEventDispatcher):void;
    function get mainWindow():IWindow;
}
```

### IRoomWidgetHandler
**File:** `src/com/sulake/habbo/ui/IRoomWidgetHandler.as`

Handles message/event processing:

```actionscript
public interface IRoomWidgetHandler extends IDisposable 
{
    function get type():String;
    function set container(_arg_1:IRoomWidgetHandlerContainer):void;
    function getWidgetMessages():Array;
    function processWidgetMessage(_arg_1:RoomWidgetMessage):RoomWidgetUpdateEvent;
    function getProcessedEvents():Array;
    function processEvent(_arg_1:Event):void;
    function update():void;
}
```

### IRoomWidgetHandlerContainer
**File:** `src/com/sulake/habbo/ui/IRoomWidgetHandlerContainer.as`

Central hub providing all services to handlers:

| Property | Service |
|----------|---------|
| `roomSession` | Current room session |
| `roomEngine` | Room rendering engine |
| `events` | Event dispatcher |
| `windowManager` | UI window system |
| `sessionDataManager` | User data |
| `catalog` | Shop system |
| `inventory` | Inventory system |
| `navigator` | Room browser |
| `friendList` | Friends list |
| `messenger` | Chat system |
| `connection` | Server connection |

## RoomWidgetBase

**File:** `src/com/sulake/habbo/ui/widget/RoomWidgetBase.as`

Base class for all room widgets:

```actionscript
public class RoomWidgetBase implements IRoomWidget
{
    protected var _handler:IRoomWidgetHandler;
    protected var _windowManager:IHabboWindowManager;
    protected var _assets:IAssetLibrary;
    protected var _localizations:IHabboLocalizationManager;
}
```

## Widget Factory

### RoomWidgetFactory
**File:** `src/com/sulake/habbo/ui/widget/RoomWidgetFactory.as`

Creates widgets by type:

```actionscript
public function createWidget(k:String, _arg_2:IRoomWidgetHandler):IRoomWidget
{
    switch (k)
    {
        case RoomWidgetEnum.CHAT_WIDGET:
            return new RoomChatWidget(...);
        case RoomWidgetEnum.ROOM_DIMMER:
            return new DimmerFurniWidget(...);
        case RoomWidgetEnum.FURNI_STICKIE_WIDGET:
            return new StickieFurniWidget(...);
        // ... 40+ types
    }
    return null;
}
```

### RoomWidgetEnum
**File:** `src/com/sulake/habbo/ui/widget/enums/RoomWidgetEnum.as`

| Constant | Widget |
|----------|--------|
| `CHAT_WIDGET` | RoomChatWidget |
| `INFOSTAND` | InfoStandWidget |
| `ME_MENU` | MeMenuWidget |
| `ROOM_DIMMER` | DimmerFurniWidget |
| `FURNI_STICKIE_WIDGET` | StickieFurniWidget |
| `FURNI_PRESENT_WIDGET` | PresentFurniWidget |
| `YOUTUBE` | YouTubeWidget |
| `CRAFTING` | CraftingWidget |

## Widget Handlers

### Handler Pattern

Each handler:
1. Defines `type` matching RoomWidgetEnum
2. Returns array of handled messages via `getWidgetMessages()`
3. Returns array of handled events via `getProcessedEvents()`
4. Processes messages/events and returns updates

### FurnitureDimmerWidgetHandler

```actionscript
public function getWidgetMessages():Array
{
    return [
        RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_DIMMER,
        RoomWidgetDimmerSavePresetMessage.RWSDPM_SAVE_PRESET,
        RoomWidgetDimmerChangeStateMessage.RWCDSM_CHANGE_STATE
    ];
}

public function processWidgetMessage(k:RoomWidgetMessage):RoomWidgetUpdateEvent
{
    switch (k.type)
    {
        case RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_DIMMER:
            // Request dimmer presets from room session
            _container.roomSession.sendRoomDimmerGetPresetsMessage();
            break;
        case RoomWidgetDimmerSavePresetMessage.RWSDPM_SAVE_PRESET:
            // Save preset
            _container.roomSession.sendRoomDimmerSavePresetMessage(...);
            break;
    }
    return null;
}
```

### FurnitureStickieWidgetHandler

```actionscript
public function getWidgetMessages():Array
{
    return [
        RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_STICKIE,
        RoomWidgetStickieSendUpdateMessage.RWSUM_STICKIE_SEND_UPDATE,
        RoomWidgetStickieSendUpdateMessage.RWSUM_STICKIE_SEND_DELETE
    ];
}

public function processWidgetMessage(k:RoomWidgetMessage):RoomWidgetUpdateEvent
{
    switch (k.type)
    {
        case RoomWidgetFurniToWidgetMessage.RWFWM_MESSAGE_REQUEST_STICKIE:
            // Get stickie data from room object model
            var text:String = roomObject.getModel().getString(
                RoomObjectVariableEnum.FURNITURE_ITEMDATA);
            // Dispatch to widget
            events.dispatchEvent(new RoomWidgetStickieDataUpdateEvent(...));
            break;
    }
    return null;
}
```

## Message Routing

### Message Types

| Message | Purpose |
|---------|---------|
| `RoomWidgetFurniToWidgetMessage` | Request furniture interaction |
| `RoomWidgetDimmerSavePresetMessage` | Save dimmer preset |
| `RoomWidgetStickieSendUpdateMessage` | Update stickie text |
| `RoomWidgetChatMessage` | Send chat message |
| `RoomWidgetUserActionMessage` | User action (wave, dance) |
| `RoomWidgetPresentOpenMessage` | Open present |

### Routing Flow

```
User Click
    │
    ▼
Widget sends RoomWidgetMessage
    │
    ▼
RoomWidgetMessageRouter
    │
    ▼
IRoomWidgetHandlerContainer.processWidgetMessage()
    │
    ▼
WidgetHandler.processWidgetMessage()
    │
    ▼
RoomEngine / RoomSession API
    │
    ▼
Server Response → RoomEvent
    │
    ▼
WidgetHandler.processEvent()
    │
    ▼
RoomWidgetUpdateEvent → Widget
```

## Widget Events

| Event | Purpose |
|-------|---------|
| `RoomWidgetChatUpdateEvent` | Chat message received |
| `RoomWidgetDimmerUpdateEvent` | Dimmer state changed |
| `RoomWidgetStickieDataUpdateEvent` | Stickie data loaded |
| `RoomWidgetPresentDataUpdateEvent` | Present opened |
| `RoomWidgetFurniInfostandUpdateEvent` | Furniture info displayed |
| `RoomWidgetUserInfoUpdateEvent` | User info displayed |
| `RoomWidgetPollUpdateEvent` | Poll state changed |

## WidgetWindowController

**File:** `src/com/sulake/core/window/components/WidgetWindowController.as`

Bridges window system with Habbo widgets:

```actionscript
// Window has WIDGET_TYPE property
// WidgetWindowController reads and creates the widget
var widget:IWidget = _widgetFactory.createWidget(widgetType, handler);
```

## Habbo Window Widgets

**Location:** `src/com/sulake/habbo/window/widgets/`

| Widget | Purpose |
|--------|---------|
| `AvatarImageWidget` | Display avatar figure |
| `BadgeImageWidget` | Display badge |
| `BalloonWidget` | Chat balloon |
| `FurnitureImageWidget` | Furniture image |
| `PetImageWidget` | Pet image |
| `RoomPreviewerWidget` | Room preview |
| `CountdownWidget` | Countdown timer |
| `ProgressIndicatorWidget` | Progress display |

### Registration

**File:** `src/com/sulake/habbo/window/widgets/WidgetClasses.as`

```actionscript
public class WidgetClasses 
{
    {
        _Str_3059[AvatarImageWidget.AVATAR_IMAGE] = AvatarImageWidget;
        _Str_3059[BadgeImageWidget.BADGE_IMAGE] = BadgeImageWidget;
        // ... all registered
    }
}
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/ui/widget/IRoomWidget.as` | Widget interface |
| `src/com/sulake/habbo/ui/widget/RoomWidgetBase.as` | Base class |
| `src/com/sulake/habbo/ui/widget/RoomWidgetFactory.as` | Widget factory |
| `src/com/sulake/habbo/ui/widget/enums/RoomWidgetEnum.as` | Widget types |
| `src/com/sulake/habbo/ui/IRoomWidgetHandler.as` | Handler interface |
| `src/com/sulake/habbo/ui/handler/FurnitureDimmerWidgetHandler.as` | Dimmer handler |
| `src/com/sulake/core/window/components/WidgetWindowController.as` | Bridge |

## Next Steps

- [Event Handling](UI-Framework/Event-Handling) - Mouse/keyboard events
- [Theming](UI-Framework/Skinning-Theming) - UI theming