# Architecture Overview

The Habbo client is a large-scale multiplayer game client built on a **component-based architecture** using the Sulake core framework. This document provides a high-level summary of the system's design and the relationships between its major subsystems.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          HABBO CLIENT                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                      HabboMain.as                               │    │
│  │              (Bootstrap & Component Initialization)              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    SULAKE CORE FRAMEWORK                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │    │
│  │  │    ICore     │  │  Component   │  │   ICoreCommunication │  │    │
│  │  │   Runtime    │  │   System     │  │      Manager         │  │    │
│  │  └──────────────┘  └──────────────┘  └─────────────────────┘  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │    │
│  │  │    Assets    │  │   Window     │  │     Logger          │  │    │
│  │  │   Library    │  │   Context    │  │                     │  │    │
│  │  └──────────────┘  └──────────────┘  └─────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                    │
│           ┌────────────────────────┼────────────────────────┐           │
│           │                        │                        │           │
│           ▼                        ▼                        ▼           │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  COMMUNICATION  │    │   ROOM ENGINE   │    │   AVATAR SYSTEM │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │ Socket   │  │    │  │ RoomMgr  │  │    │  │ Avatar    │  │     │
│  │  │Connection│  │    │  │           │  │    │  │ RenderMgr │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │ Messages │  │    │  │ RoomInst │  │    │  │ Avatar    │  │     │
│  │  │(500+ Composers)│ │  │           │  │    │  │ Structure │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │Encryption│  │    │  │Renderer  │  │    │  │FigureData │  │     │
│  │  │ RC4, DH  │  │    │  │           │  │    │  │ Parser    │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                    │                                    │
│           ┌────────────────────────┼────────────────────────┐           │
│           │                        │                        │           │
│           ▼                        ▼                        ▼           │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  WINDOW MANAGER │    │  INVENTORY      │    │    CATALOG      │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │HabboWin  │  │    │  │ Habbo    │  │    │  │ Habbo    │  │     │
│  │  │Manager   │  │    │  │ Inventory│  │    │  │ Catalog  │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │ Widgets  │  │    │  │ Furni    │  │    │  │ Product   │  │     │
│  │  │          │  │    │  │ Model    │  │    │  │ Viewer    │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                    │                                    │
│           ┌────────────────────────┼────────────────────────┐           │
│           │                        │                        │           │
│           ▼                        ▼                        ▼           │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │   NAVIGATOR     │    │   MESSENGER     │    │    QUEST ENGINE │     │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │     │
│  │  │HabboNav  │  │    │  │ Habbo    │  │    │  │ Habbo    │  │     │
│  │  │          │  │    │  │Messenger │  │    │  │QuestEng  │  │     │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Principles

### 1. Component-Based Architecture

The client uses a **dependency injection** pattern through the Sulake core framework:

- **Components** are self-contained modules that expose functionality through interfaces
- **IID (Interface IDs)** are used to request dependencies
- **Component dependencies** are declared and resolved at initialization time

```actionscript
// Example: Component declaration
override protected function get dependencies():Vector.<ComponentDependency>
{
    return (super.dependencies.concat(new <ComponentDependency>[
        new ComponentDependency(new IIDHabboConfigurationManager(), null, false, [
            { "type": Event.COMPLETE, "callback": this.onConfigurationComplete }
        ])
    ]));
}
```

### 2. Event-Driven Communication

Subsystems communicate through a centralized **event dispatching system**:

- Flash's native `Event` and `EventDispatcher` classes
- Custom event types for domain-specific messages
- Both synchronous and asynchronous event handling

### 3. Layered Rendering

The room rendering system uses a layered approach:

```
┌─────────────────────────────────────────┐
│         RoomSpriteCanvas (UI)           │  ← Top layer (chat, cursors)
├─────────────────────────────────────────┤
│         RoomObjectLayer (Objects)       │  ← Avatars, furniture
├─────────────────────────────────────────┤
│         RoomVisualization (Room)       │  ← Floor, walls, masks
└─────────────────────────────────────────┘
```

### 4. Message-Based Networking

All client-server communication uses a **message composer/parser pattern**:

- **Composers** serialize outgoing data into binary format
- **Parsers** deserialize incoming data from binary format
- **Events** route incoming messages to handlers

## Key Subsystem Responsibilities

| Subsystem | Responsibility | Entry Point |
|-----------|----------------|-------------|
| **Communication** | TCP connection, encryption, message routing | `HabboCommunicationManager` |
| **Room Engine** | Room rendering, object management, interactions | `RoomEngine` |
| **Avatar System** | Figure parsing, avatar rendering, animations | `AvatarRenderManager` |
| **Window Manager** | UI window creation, widget management | `HabboWindowManagerComponent` |
| **Inventory** | Furniture items, trading, badges | `HabboInventory` |
| **Catalog** | Product display, purchasing | `HabboCatalog` |
| **Navigator** | Room search, categories | `HabboNavigator` |
| **Messenger** | Chat, friend messages | `HabboMessenger` |

## Data Flow Patterns

### Network Communication

```
User Action → MessageComposer → SocketConnection → Network
                                                            │
Network ← Parser ← MessageEvent ← SocketConnection ← Server
```

### Room Rendering

```
Server Data → RoomMessageHandler → RoomInstance → RoomRenderer → Canvas
```

### UI Updates

```
Server Data → MessageEvent → Internal Event → Widget/Window Update
```

## Dependency Graph

```
                    ┌─────────────────────┐
                    │      HabboMain      │
                    │  (Bootstrap)        │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
    ┌─────────────────┐ ┌───────────────┐ ┌──────────────┐
    │     Core       │ │  Communication│ │ WindowManager│
    │  (Runtime)     │ │    Manager    │ │              │
    └────────┬───────┘ └───────┬───────┘ └──────┬───────┘
             │                 │                 │
             │        ┌────────┴────────┐        │
             │        │                 │        │
             ▼        ▼                 ▼        ▼
    ┌──────────────┐ ┌─────────────┐ ┌────────────┐
    │ Room Engine  │ │  Inventory  │ │  Catalog   │
    │              │ │              │ │            │
    └──────┬───────┘ └─────────────┘ └────────────┘
           │
    ┌──────┴───────┐
    │              │
    ▼              ▼
┌────────┐  ┌────────────┐
│Avatar  │  │  Furniture │
│System  │  │  System    │
└────────┘  └────────────┘
```

## Session Model

The client follows a **session-based** model:

1. **Connection Session** - TCP connection with authentication
2. **Room Session** - Active room (can have multiple for preloading)
3. **User Session** - User data, inventory, friend list

Each session type has dedicated event handling and state management.

## Next Steps

- [Application Lifecycle](Architecture/Application-Lifecycle) - Detailed boot sequence
- [Component Model](Architecture/Component-Model) - Sulake framework details
- [Networking](Core-Systems/Networking) - Protocol and encryption
