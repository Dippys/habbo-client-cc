# Habbo Client Documentation

Welcome to the comprehensive documentation for the Habbo client codebase. This wiki provides detailed documentation of the architecture, systems, and patterns used in the ActionScript 3 client.

## Table of Contents

### Architecture
- [Architecture Overview](Architecture/Overview) - High-level system summary
- [Application Lifecycle](Architecture/Application-Lifecycle) - Boot sequence, initialization, runtime
- [Component Model](Architecture/Component-Model) - Sulake core framework
- [Directory Structure](Architecture/Directory-Structure) - Package organization

### Core Systems
#### Room Engine
- [Room Engine Architecture](Core-Systems/Room-Engine/Architecture) - Overview and components
- [Object Lifecycle](Core-Systems/Room-Engine/Object-Lifecycle) - Create, update, dispose
- [Rendering](Core-Systems/Room-Engine/Rendering) - RoomRenderer, canvases
- [Heightmaps](Core-Systems/Room-Engine/Heightmaps) - Tile geometry and positioning

#### Avatar System
- [Avatar Rendering](Core-Systems/Avatar-System/Rendering) - AvatarImage, rendering pipeline
- [Figure Data](Core-Systems/Avatar-System/Figure-Data) - Figure strings, parsing
- [Actions and Animations](Core-Systems/Avatar-System/Actions) - Animations, postures, gestures
- [Caching System](Core-Systems/Avatar-System/Caching) - Cache hierarchy and management

#### Furniture System
- [Furniture Architecture](Core-Systems/Furniture-System/Architecture) - Furniture logic and visualization
- [Interactions](Core-Systems/Furniture-System/Interactions) - Click, use, state changes
- [Furniture Types](Core-Systems/Furniture-System/Types) - Specialized furniture types

#### Networking
- [Networking](Core-Systems/Networking) - Connection management, socket handling

### UI Framework
- [Window Manager](UI-Framework/Window-Manager) - Window hierarchy and management
- [Widget System](UI-Framework/Widget-System) - Room widgets and UI widgets
- [Event Handling](UI-Framework/Event-Handling) - Mouse and keyboard events
- [Theming](UI-Framework/Skinning-Theming) - Themes and XML layouts

### Features
- [Inventory](Features/Inventory) - Furniture inventory management
- [Catalog](Features/Catalog) - Shop system
- [Navigator](Features/Navigator) - Room browser
- [Messenger](Features/Messenger) - Chat and messaging
- [Quests](Features/Quests) - Achievements and quests
- [Groups](Features/Groups) - Guild system

### Asset Pipeline
- [Asset Libraries](Asset-Pipeline/Asset-Libraries) - Loading and management
- [Figure System](Asset-Pipeline/Figure-System) - Asset resolution

### Protocol
- [Wire Format](Protocol/Wire-Format) - EvaWireFormat binary framing
- [Message Pattern](Protocol/Message-Pattern) - Message structure and headers
- [Encryption](Protocol/Encryption) - RC4 and Diffie-Hellman
- [Packet Reference](Protocol/Packet-Reference) - Packet IDs and mappings

### Data Flows
- [Client-Server Communication](Data-Flows/Client-Server-Communication) - Packet flow
- [Room Interactions](Data-Flows/Room-Interactions) - Room enter/leave flow
- [Furniture Interactions](Data-Flows/Furniture-Interactions) - Furniture click/use flow
- [Avatar Rendering Flow](Data-Flows/Avatar-Rendering-Flow) - Figure to render pipeline

### Development
- [Coding Conventions](Development/Coding-Conventions) - Code style and patterns
- [Troubleshooting](Development/Troubleshooting) - Common issues and solutions

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
