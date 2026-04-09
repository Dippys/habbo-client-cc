# Event Handling

The Event Handling system manages all user input - mouse, keyboard, and touch - converting Flash native events into the window system's event framework.

## Event System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EVENT HANDLING ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Flash Native Events                             │   │
│  │                                                                       │   │
│  │  MouseEvent    KeyboardEvent    TouchEvent                         │   │
│  │  - CLICK       - KEY_DOWN       - BEGIN                           │   │
│  │  - MOUSE_DOWN  - KEY_UP         - END                             │   │
│  │  - MOUSE_UP    - charCode       - MOVE                            │   │
│  │  - MOVE        - keyCode        - TAP                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   Event Processors                                  │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │MouseEventProcessor│  │KeyboardEvent    │  │ TouchEvent     │   │   │
│  │  │                  │  │ Processor       │  │ Processor       │   │   │
│  │  │ - Hit testing    │  │                 │  │                 │   │   │
│  │  │ - Event convert  │  │ - Event convert │  │ - Event convert │   │   │
│  │  │ - Hover track   │  │                 │  │                 │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Window Events                                  │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │WindowMouseEvent  │  │WindowKeyboard    │  │ WindowEvent    │   │   │
│  │  │                  │  │    Event         │  │                 │   │   │
│  │  │ - CLICK         │  │ - KEY_DOWN      │  │ - FOCUS        │   │   │
│  │  │ - ROLL_OVER     │  │ - KEY_UP        │  │ - RESIZE       │   │   │
│  │  │ - DOUBLE_CLICK  │  │ - charCode      │  │ - ACTIVATE     │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  Object Pool Pattern - allocate()/recycle() for memory efficiency   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              WindowEventDispatcher                                  │   │
│  │                                                                       │   │
│  │  - Dictionary<type -> Array<EventListener>>                        │   │
│  │  - addEventListener / removeEventListener / dispatchEvent          │   │
│  │  - Priority-based ordering                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## WindowMouseEvent

**File:** `src/com/sulake/core/window/events/WindowMouseEvent.as`

Mouse events with object pooling:

### Event Types

| Type | Description |
|------|-------------|
| `CLICK` | Mouse button clicked |
| `DOUBLE_CLICK` | Double-click |
| `DOWN` | Mouse button pressed |
| `UP` | Mouse button released (inside) |
| `UP_OUTSIDE` | Mouse button released (outside) |
| `OVER` | Mouse entered window |
| `OUT` | Mouse left window |
| `ROLL_OVER` | Mouse rolled over (no capture) |
| `ROLL_OUT` | Mouse rolled out (no capture) |
| `MOVE` | Mouse moved within window |
| `WHEEL` | Mouse wheel scrolled |
| `RIGHT_CLICK` | Right-click |
| `HOVERING` | Mouse hovering (periodic) |

### Properties

```actionscript
public var delta:int           // Mouse wheel delta
public var localX:Number       // X relative to window
public var localY:Number       // Y relative to window
public var stageX:Number       // X relative to stage
public var stageY:Number       // Y relative to stage
public var altKey:Boolean      // Alt pressed
public var ctrlKey:Boolean     // Ctrl pressed
public var shiftKey:Boolean    // Shift pressed
public var buttonDown:Boolean  // Button held down
```

### Object Pool Usage

```actionscript
// Allocate from pool
var event:WindowMouseEvent = WindowMouseEvent.allocate(
    WindowMouseEvent.CLICK, window, related,
    localX, localY, stageX, stageY,
    altKey, ctrlKey, shiftKey, buttonDown, delta
);

// After use, return to pool
event.recycle();
```

## WindowKeyboardEvent

**File:** `src/com/sulake/core/window/events/WindowKeyboardEvent.as`

Keyboard events wrapping Flash events:

### Event Types

| Type | Description |
|------|-------------|
| `WINDOW_EVENT_KEY_UP` | Key released |
| `WINDOW_EVENT_KEY_DOWN` | Key pressed |

### Properties

```actionscript
public function get charCode():uint      // Character code
public function get keyCode():uint       // Key code
public function get keyLocation():uint   // Key location
public function get altKey():Boolean      // Alt modifier
public function get shiftKey():Boolean   // Shift modifier
public function get ctrlKey():Boolean    // Ctrl modifier
```

### Implementation

```actionscript
// Internally wraps flash.events.KeyboardEvent
private var _event:KeyboardEvent;
```

## WindowEvent

**File:** `src/com/sulake/core/window/events/WindowEvent.as`

Base class for all window events:

### Lifecycle Events

| Type | Description |
|------|-------------|
| `WINDOW_EVENT_DESTROY/DESTROYED` | Window destruction |
| `WINDOW_EVENT_OPEN/OPENED` | Window opening |
| `WINDOW_EVENT_CLOSE/CLOSED` | Window closing |

### Focus Events

| Type | Description |
|------|-------------|
| `WINDOW_EVENT_FOCUS/FOCUSED` | Gaining focus |
| `WINDOW_EVENT_UNFOCUS/UNFOCUSED` | Losing focus |

### Activation Events

| Type | Description |
|------|-------------|
| `WINDOW_EVENT_ACTIVATE/ACTIVATED` | Window activated |
| `WINDOW_EVENT_DEACTIVATE/DEACTIVATED` | Window deactivated |

### Layout Events

| Type | Description |
|------|-------------|
| `WINDOW_EVENT_RELOCATE/RELOCATED` | Position changed |
| `WINDOW_EVENT_RESIZE/RESIZED` | Size changed |
| `WINDOW_EVENT_MINIMIZE/MINIMIZED` | Minimized |
| `WINDOW_EVENT_MAXIMIZE/MAXIMIZED` | Maximized |

### Key Properties

```actionscript
public function get type():String
public function get target():IWindow
public function get window():IWindow
public function get related():IWindow
public function get cancelable():Boolean
```

### Key Methods

```actionscript
// Prevent default action
function preventDefault():void

// Cancel window operation
function preventWindowOperation():void

// Return to object pool
function recycle():void
```

## Event Processors

### MouseEventProcessor
**File:** `src/com/sulake/core/window/utils/MouseEventProcessor.as`

Converts Flash events to window events:

```actionscript
// Event conversion mapping
switch (k.type)
{
    case MouseEvent.MOUSE_MOVE:  return WindowMouseEvent.MOVE;
    case MouseEvent.MOUSE_OVER:  return WindowMouseEvent.OVER;
    case MouseEvent.MOUSE_OUT:   return WindowMouseEvent.OUT;
    case MouseEvent.CLICK:       return WindowMouseEvent.CLICK;
    case MouseEvent.MOUSE_DOWN:  return WindowMouseEvent.DOWN;
    case MouseEvent.MOUSE_UP:    return WindowMouseEvent.UP;
}
```

### Key Responsibilities

1. **Hit Testing**: Find target window under mouse
2. **Event Conversion**: Convert Flash events to Window events
3. **Hover Tracking**: Track current hover window
4. **Click Target**: Remember clicked window for mouse-up

## WindowEventDispatcher

**File:** `src/com/sulake/core/window/events/WindowEventDispatcher.as`

Manages event listeners:

```actionscript
// Add listener
window.addEventListener(WindowMouseEvent.CLICK, onClick);

// Remove listener
window.removeEventListener(WindowMouseEvent.CLICK, onClick);

// Dispatch
window.dispatchEvent(event);
```

### Features

- **Priority-based ordering**: Higher priority listeners execute first
- **Duplicate prevention**: Same callback can't register twice
- **Safe iteration**: Copies callbacks before execution

## Input Event Tracking

**File:** `src/com/sulake/core/window/IInputEventTracker.as`

Allows external components to observe all window events:

```actionscript
public interface IInputEventTracker 
{
    function eventReceived(event:WindowEvent, window:IWindow):void;
}
```

Trackers are stored in `WindowContext` and receive events during processing.

## Additional Event Types

### WindowLinkEvent
**File:** `src/com/sulake/core/window/events/WindowLinkEvent.as`

```actionscript
public static const WINDOW_EVENT_LINK:String = "WE_LINK";
public var link:String  // Link identifier
```

### WindowTouchEvent
**File:** `src/com/sulake/core/window/events/WindowTouchEvent.as`

| Type | Description |
|------|-------------|
| `WTE_BEGIN` | Touch began |
| `WTE_END` | Touch ended |
| `WTE_MOVE` | Touch moved |
| `WTE_TAP` | Tap gesture |

## Event Flow

```
Flash Event
    │
    ▼
EventProcessor.process() [hit testing, conversion]
    │
    ▼
WindowMouseEvent.allocate() [object pool]
    │
    ▼
WindowController.update() [calls procedure]
    │
    ▼
WindowEventDispatcher.dispatchEvent() [notifies listeners]
    │
    ▼
Event.recycle() [return to pool]
```

## Usage Example

```actionscript
// Register for mouse events
button.addEventListener(WindowMouseEvent.CLICK, onButtonClick);
button.addEventListener(WindowMouseEvent.ROLL_OVER, onButtonHover);

// Event handler
private function onButtonClick(event:WindowMouseEvent):void
{
    // Handle click
    trace("Clicked at:", event.stageX, event.stageY);
}

// Cleanup
button.removeEventListener(WindowMouseEvent.CLICK, onButtonClick);
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/core/window/events/WindowMouseEvent.as` | Mouse events |
| `src/com/sulake/core/window/events/WindowKeyboardEvent.as` | Keyboard events |
| `src/com/sulake/core/window/events/WindowEvent.as` | Base event class |
| `src/com/sulake/core/window/events/WindowEventDispatcher.as` | Event dispatching |
| `src/com/sulake/core/window/utils/MouseEventProcessor.as` | Event conversion |
| `src/com/sulake/core/window/IInputEventTracker.as` | Input tracking |

## Next Steps

- [Theming](UI-Framework/Skinning-Theming) - UI theming and skins