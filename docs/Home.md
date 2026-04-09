# Habbo Client Documentation

Welcome to the comprehensive documentation for the Habbo client codebase. This wiki provides detailed documentation of the architecture, systems, and patterns used in the ActionScript 3 client.

## Table of Contents

### Architecture
- [Architecture Overview](Architecture/Overview.md) - High-level system summary
- [Application Lifecycle](Architecture/Application-Lifecycle.md) - Boot sequence, initialization, runtime
- [Component Model](Architecture/Component-Model.md) - Sulake core framework
- [Directory Structure](Architecture/Directory-Structure.md) - Package organization

### Core Systems
#### Room Engine
- [Room Engine Architecture](Core-Systems/Room-Engine/Architecture.md) - Overview and components
- [Object Lifecycle](Core-Systems/Room-Engine/Object-Lifecycle.md) - Create, update, dispose
- [Rendering](Core-Systems/Room-Engine/Rendering.md) - RoomRenderer, canvases
- [Heightmaps](Core-Systems/Room-Engine/Heightmaps.md) - Tile geometry and positioning

#### Avatar System
- [Avatar Rendering](Core-Systems/Avatar-System/Rendering.md) - AvatarImage, rendering pipeline
- [Figure Data](Core-Systems/Avatar-System/Figure-Data.md) - Figure strings, parsing
- [Actions and Animations](Core-Systems/Avatar-System/Actions.md) - Animations, postures, gestures
- [Caching System](Core-Systems/Avatar-System/Caching.md) - Cache hierarchy and management

#### Furniture System
- [Furniture Architecture](Core-Systems/Furniture-System/Architecture.md) - Furniture logic and visualization
- [Interactions](Core-Systems/Furniture-System/Interactions.md) - Click, use, state changes
- [Furniture Types](Core-Systems/Furniture-System/Types.md) - Specialized furniture types

#### Networking
- [Networking](Core-Systems/Networking.md) - Connection management, socket handling

### UI Framework
- [Window Manager](UI-Framework/Window-Manager.md) - Window hierarchy and management
- [Widget System](UI-Framework/Widget-System.md) - Room widgets and UI widgets
- [Event Handling](UI-Framework/Event-Handling.md) - Mouse and keyboard events
- [Theming](UI-Framework/Skinning-Theming.md) - Themes and XML layouts

### Features
- [Inventory](Features/Inventory.md) - Furniture inventory management
- [Catalog](Features/Catalog.md) - Shop system
- [Navigator](Features/Navigator.md) - Room browser
- [Messenger](Features/Messenger.md) - Chat and messaging
- [Quests](Features/Quests.md) - Achievements and quests
- [Groups](Features/Groups.md) - Guild system

### Asset Pipeline
- [Asset Libraries](Asset-Pipeline/Asset-Libraries.md) - Loading and management
- [Figure System](Asset-Pipeline/Figure-System.md) - Asset resolution

### Protocol
- [Wire Format](Protocol/Wire-Format.md) - EvaWireFormat binary framing
- [Message Pattern](Protocol/Message-Pattern.md) - Message structure and headers
- [Encryption](Protocol/Encryption.md) - RC4 and Diffie-Hellman
- [Packet Reference](Protocol/Packet-Reference.md) - Packet IDs and mappings

### Data Flows
- [Client-Server Communication](Data-Flows/Client-Server-Communication.md) - Packet flow
- [Room Interactions](Data-Flows/Room-Interactions.md) - Room enter/leave flow
- [Furniture Interactions](Data-Flows/Furniture-Interactions.md) - Furniture click/use flow
- [Avatar Rendering Flow](Data-Flows/Avatar-Rendering-Flow.md) - Figure to render pipeline

### Development
- [Coding Conventions](Development/Coding-Conventions.md) - Code style and patterns
- [Troubleshooting](Development/Troubleshooting.md) - Common issues and solutions

---

## Quick Reference

### Technology Stack
- **Language:** ActionScript 3
- **Framework:** Sulake Core (component-based)
- **Protocol:** Binary TCP with EvaWireFormat framing
- **Encryption:** RC4 stream cipher with Diffie-Hellman key exchange
- **Rendering:** Custom isometric sprite renderer

### Key Entry Points
| Class | File | Purpose |
|-------|------|---------|
| `HabboMain` | `src/HabboMain.as` | Bootstrap and component initialization |
| `Habbo` | `src/Habbo.as` | Main application controller |
| `HabboCommunicationManager` | `src/com/sulake/habbo/communication/HabboCommunicationManager.as` | Connection management |
| `RoomEngine` | `src/com/sulake/habbo/room/RoomEngine.as` | Room rendering engine |
| `AvatarRenderManager` | `src/com/sulake/habbo/avatar/AvatarRenderManager.as` | Avatar rendering |
| `HabboWindowManagerComponent` | `src/com/sulake/habbo/window/HabboWindowManagerComponent.as` | UI window management |

### Package Overview
```
com/sulake/
├── core/           # Sulake framework (runtime, communication, assets, windows)
└── habbo/          # Habbo-specific implementations
    ├── communication/   # Protocol, messages
    ├── room/             # Room engine
    ├── avatar/           # Avatar rendering
    ├── window/           # UI system
    ├── inventory/        # Inventory
    ├── catalog/         # Shop
    ├── navigator/       # Room browser
    ├── messenger/       # Chat
    └── [20+ more]       # Other features
```

---

## Contributing

When adding new documentation:
1. Follow the page structure in each section
2. Use ASCII diagrams for visual explanations
3. Include code examples from the actual codebase
4. Cross-reference related pages

---

*This documentation was generated from code analysis of the habbo-client-clean repository.*
