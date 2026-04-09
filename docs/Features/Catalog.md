# Catalog

The catalog is the in-game shop. It's the largest feature package in the client (~104 files under `src/com/sulake/habbo/catalog/`) because it drives not only purchasing but also marketplace listings, targeted offers, club membership, recycler / trophies, VIP lounges, and video-offer promotions.

## Entry Point

| Class / Interface              | File                                                              | Role                                                           |
|--------------------------------|-------------------------------------------------------------------|----------------------------------------------------------------|
| `HabboCatalog`                 | `src/com/sulake/habbo/catalog/HabboCatalog.as`                    | Sulake `Component`. Caches catalog index, serves `getPage()`, owns the main window, orchestrates purchase confirmation |
| `IHabboCatalog`                | `src/com/sulake/habbo/catalog/IHabboCatalog.as`                    | Interface other components (room engine, inventory, quest) consume |
| `HabboCatalogUtils`            | `src/com/sulake/habbo/catalog/HabboCatalogUtils.as`                | Stateless helpers: price formatting, discount math, credit/pixel splits |

`HabboCatalog` is registered at boot as `HabboCatalogCom` (component #20; see [Application Lifecycle](../Architecture/Application-Lifecycle.md)).

## Package Layout

```
src/com/sulake/habbo/catalog/
├── HabboCatalog.as
├── IHabboCatalog.as
├── enum/              # ProductTypeEnum, CatalogPageName, CatalogWidgetEnum, etc.
├── navigation/        # Catalog tree (pages + sub-pages)
├── viewer/            # Rendering a single page
│   └── widgets/       # PurchaseCatalogWidget, PreviewCatalogWidget, MarketPlaceCatalogWidget, …
├── offers/            # Offer data model
├── purchase/          # Purchase confirmation dialogs and state machine
├── marketplace/       # Marketplace (user-to-user item sales)
├── club/              # Habbo Club subscriptions
├── clubcenter/
├── guilds/            # Guild-badge purchase flow
├── recycler/          # Ecotron / trophy crafting
└── targetedoffers/    # Personalised promotional offers
```

## Page Loading

Pages are **layout-driven**. Each server-authored catalog page carries a `layoutCode` string that tells the client which widgets to instantiate. This is how Sulake could change page designs without reshipping the SWF.

1. Client sends `GetCatalogIndexComposer` on first open → server returns the full catalog tree as `CatalogPagesListEvent` (packet 1032).
2. User clicks a page in the navigation tree.
3. Client sends `GetCatalogPageComposer(pageId, offerId, catalogType)`.
4. Server replies with a `CatalogPageMessageEvent` — parsed by `CatalogPageMessageParser` in `src/com/sulake/habbo/communication/messages/parser/catalog/`. The parser reads `layoutCode`, a localization block, a vector of `Offer` rows, and a set of layout-specific parameters.
5. `CatalogPage` in `viewer/` inspects the `layoutCode`, loads the corresponding XML skin (see [UI-Framework/Skinning-Theming](../UI-Framework/Skinning-Theming.md)), then instantiates widgets listed via `CatalogWidgetEnum`.
6. Widgets like `PurchaseCatalogWidget` bind to DOM nodes in the XML by name and take over click handlers.

Layout codes seen in the wild include `frontpage_featured`, `default_3x3`, `club_gift`, `spaces_new`, `recycler`, `single_bundle`, `marketplace` — each maps to a distinct widget combination.

## Purchase Flow

```
┌──────────────────────┐    ┌──────────────────────┐    ┌────────────────────────┐
│ PurchaseCatalogWidget│───▶│ HabboCatalog         │───▶│ PurchaseConfirmation   │
│   .onBuyClicked()    │    │ .showPurchaseConfirm │    │ Dialog                 │
└──────────────────────┘    └──────────────────────┘    └──────────┬─────────────┘
                                                                   │
                                                                   ▼
                                                        ┌────────────────────────┐
                                                        │ PurchaseFromCatalog    │
                                                        │ MessageComposer        │
                                                        └──────────┬─────────────┘
                                                                   │ (network)
                                                                   ▼
                                                        ┌────────────────────────┐
                                                        │ PurchaseOKMessageEvent │
                                                        │ (or PurchaseError)     │
                                                        └──────────┬─────────────┘
                                                                   │
                                          ┌────────────────────────┴────────┐
                                          ▼                                 ▼
                                ┌──────────────────┐             ┌────────────────────┐
                                │ Inventory (furni)│             │ Purse update       │
                                │ gets new item    │             │ (credits / pixels) │
                                └──────────────────┘             └────────────────────┘
```

- The "buy as gift" flow uses a parallel composer — `PurchaseFromCatalogAsGiftComposer` — plus `GiftWrappingConfigurationEvent` which tells the client which wrappings / ribbons are available.
- Price quotes for parameterised offers (e.g. rooms, photo prints) require a preview round-trip: client sends `GetProductOfferComposer`, server returns a confirmed price.

## Marketplace

The marketplace is the user-to-user item resale system embedded in the catalog.

| Class                                       | File                                                                  | Role                                   |
|---------------------------------------------|-----------------------------------------------------------------------|----------------------------------------|
| `MarketPlaceLogic`                          | `src/com/sulake/habbo/catalog/marketplace/MarketPlaceLogic.as`        | State + action dispatch                |
| `MarketPlaceOfferData`                      | `src/com/sulake/habbo/catalog/marketplace/MarketPlaceOfferData.as`    | Data model for a single listing        |
| `MarketplaceChart`                          | `src/com/sulake/habbo/catalog/marketplace/MarketplaceChart.as`        | Price-history mini-chart               |
| `MarketplaceConfirmationDialog`             | `src/com/sulake/habbo/catalog/marketplace/MarketplaceConfirmationDialog.as` | Buy/sell confirmation        |
| `MarketPlaceCatalogWidget`                  | `src/com/sulake/habbo/catalog/viewer/widgets/MarketPlaceCatalogWidget.as` | Page widget                       |

The marketplace piggybacks on the catalog page layout system via a dedicated layout code that mounts `MarketPlaceCatalogWidget` in place of normal purchase widgets.

## Relevant Packets

See the [Packet Reference](../Protocol/Packet-Reference.md) for every ID. Highlights:

**Incoming — catalog core:**
- `CatalogPagesListEvent` (1032) — the navigation tree
- `CatalogPageMessageEvent` — a single page's widgets + offers
- `CatalogPageExpirationEvent` — limited-time offer countdown
- `PurchaseOKMessageEvent` — purchase succeeded
- `PurchaseErrorMessageEvent` (1404) — purchase failed (OOC, sold-out, etc.)
- `GiftWrappingConfigurationEvent` — available gift wraps
- `TargetedOfferEvent` (119), `TargetedOfferNotFoundEvent` (1237)
- `LimitedOfferAppearingNextMessageEvent` (44)

**Incoming — marketplace:**
- `MarketPlaceOffersEvent`
- `MarketplaceItemStatsEvent`
- `MarketplaceBuyOfferResultEvent`
- `MarketplaceMakeOfferResult` (1359)

**Outgoing — catalog core:**
- `GetCatalogIndexComposer`
- `GetCatalogPageComposer`
- `GetProductOfferComposer`
- `PurchaseFromCatalogComposer`
- `PurchaseFromCatalogAsGiftComposer`

**Outgoing — marketplace:**
- `GetMarketplaceOffersMessageComposer`
- `BuyMarketplaceOfferMessageComposer`
- `MakeOfferMessageComposer`
- `GetMarketplaceItemStatsComposer`

## Cross-references

- [Features/Inventory](Inventory.md) — purchased items are delivered here
- [Features/Groups](Groups.md) — guild badge purchases use a dedicated catalog flow under `catalog/guilds/`
- [Furniture System Architecture](../Core-Systems/Furniture-System/Architecture.md) — how a just-bought furni becomes a placeable room object
- [UI-Framework/Skinning-Theming](../UI-Framework/Skinning-Theming.md) — the XML layout system catalog pages build on
- [Protocol/Packet Reference](../Protocol/Packet-Reference.md) — complete ID list for `catalog/` and `marketplace/`
