# Inventory

The inventory system lets players browse, manage, and act on everything they own: furni, clothing effects, pets, badges, bots, trophies — plus the trading UI built on top of it. It is one of the larger feature packages: ~50 files under `src/com/sulake/habbo/inventory/`.

## Entry Point

| Class / Interface              | File                                                              | Role                                               |
|--------------------------------|-------------------------------------------------------------------|----------------------------------------------------|
| `HabboInventory`               | `src/com/sulake/habbo/inventory/HabboInventory.as`                | Sulake `Component` — wires up categories, incoming packet handlers, unseen tracking, window lifecycle |
| `IHabboInventory`              | `src/com/sulake/habbo/inventory/IHabboInventory.as`                | Public interface other components (catalog, room engine) depend on |
| `InventoryMainView`            | `src/com/sulake/habbo/inventory/InventoryMainView.as`              | The tabbed window the user actually sees          |
| `IncomingMessages`             | `src/com/sulake/habbo/inventory/IncomingMessages.as`               | Subscribes to all inventory-related packets and dispatches to the right sub-model |
| `UnseenItemTracker`            | `src/com/sulake/habbo/inventory/UnseenItemTracker.as`              | Red-dot "new" indicators per category              |

`HabboInventory` is registered by `HabboMain` as `HabboInventoryCom` (see `Application-Lifecycle` doc, component #18 in the boot order).

## Category Sub-systems

Inventory follows a strict **Model / View** split per category. Each category lives in its own subfolder and exposes an `IInventoryModel` + `IInventoryView` pair.

| Category   | Folder                                        | Model                | View                |
|------------|-----------------------------------------------|----------------------|---------------------|
| Furni      | `inventory/furni/`                            | `FurniModel.as`      | `FurniView.as`      |
| Clothing FX| `inventory/effects/`                          | `EffectsModel.as`    | `EffectsView.as`    |
| Badges     | `inventory/badges/`                           | `BadgesModel.as`     | `BadgesView.as`     |
| Pets       | `inventory/pets/`                             | `PetsModel.as`       | `PetsView.as`       |
| Bots       | `inventory/bots/`                             | `BotsModel.as`       | `BotsView.as`       |
| Purse      | `inventory/purse/`                            | `Purse.as`           | — (toolbar-driven)  |
| Trading    | `inventory/trading/`                          | `TradingModel.as`    | `TradingView.as`    |

**Furni** has an extra `FurniGridView` for the icon grid and drag-to-place interaction. **Pets** uses `PetsGridItem.as` per entry.

## Opening the Inventory

1. User clicks the inventory icon on the toolbar.
2. Toolbar dispatches `HabboToolbarEvent.TOOL_BAR_CLICK_EVENT` with target `"inventory"`.
3. `HabboInventory` calls through to the window manager (`IHabboWindowManager`) to show / hide `InventoryMainView`.
4. `InventoryMainView` lazy-loads the model/view pair for the currently selected tab — nothing is parsed or rendered until its tab is first opened.

The tabbed main view is assembled in `InventoryMainView.as`. Each tab has its own XML layout skin (see [UI-Framework/Skinning-Theming](../UI-Framework/Skinning-Theming)); tab labels come from localization keys like `"${inventory.tab.furniture}"`.

## Trading Subsystem

Trading reuses the furni grid visuals but is gated behind a state machine inside `TradingModel`:

```
IDLE  ─▶ opening  ─▶  adding items  ─▶  both confirmed  ─▶  complete  ─▶  IDLE
  ▲                          │                                 │
  └────── closed ◀───────────┴────── cancelled ◀───────────────┘
```

- **Opening:** Client sends `OpenTradingMessageComposer`; the room engine checks the target avatar is adjacent. Server replies with `TradingOpenEvent` or an error.
- **Item offers:** `AddItemToTradeComposer` adds a furni slot to your side of the trade. The server relays both sides via `TradingListItemEvent`.
- **Two-phase confirm:** Both users must click "Accept" twice — once to signal their item set is final (`TradingAcceptComposer`), then a second time after reviewing the other side (`TradingConfirmationComposer`).
- **Completion / cancellation:** `TradingCompletedEvent` (success) or `TradingCloseEvent` / `TradingOtherNotAllowedEvent` (failure).

The UI for this lives in `TradingView`; data structures come from `ItemDataStructure.as` in the parser tree.

## Relevant Packets

See the [Packet Reference](../Protocol/Packet-Reference) for every ID. Highlights:

**Incoming — furniture:**
- `FurniListEvent` — initial inventory snapshot
- `FurniListAddOrUpdateEvent` (104)
- `FurniListRemoveEvent` (159)
- `FurniListInvalidateEvent`

**Incoming — trading:**
- `TradingOpenEvent`, `TradingListItemEvent`, `TradingAcceptEvent`, `TradingConfirmationEvent`
- `TradingCompletedEvent` (1001), `TradingCloseEvent` (1373), `TradingOtherNotAllowedEvent` (1254)

**Incoming — pets / badges / effects:**
- `PetInventoryEvent`, `PetAddedToInventoryEvent`, `PetReceivedMessageEvent` (1111)
- `UserBadgesEvent` (1087), `BadgeReceivedEvent`
- `AvatarEffectMessageEvent` (1167), `AvatarEffectActivatedMessageEvent`

**Outgoing:**
- `RequestFurniInventoryComposer`
- `OpenTradingComposer`, `AddItemToTradeComposer`, `AcceptTradingComposer`, `CloseTradingComposer`
- `GetPetInventoryComposer`
- `GetBadgesComposer`, `SetActivatedBadgesComposer`
- `AvatarEffectActivatedComposer`, `AvatarEffectSelectedComposer`

## Cross-references

- [Furniture System Architecture](../Core-Systems/Furniture-System/Architecture) — placement of furni onto a room after drag-from-inventory
- [Catalog](Catalog) — how newly purchased items appear in the furni inventory
- [Features/Messenger](Messenger) — trading partner identification runs through friend data
- [Protocol/Packet Reference — inventory](../Protocol/Packet-Reference) — complete ID list
