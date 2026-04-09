# Navigator

The navigator is the room browser: how players discover rooms, search by name/tag/category, manage favourites, and walk into public spaces. The codebase ships **two implementations side by side** — the legacy navigator and the "new navigator" rewrite — both under the same `src/com/sulake/habbo/navigator/` folder.

## Entry Points

| Class                     | File                                                           | Role                                   |
|---------------------------|----------------------------------------------------------------|----------------------------------------|
| `HabboNavigator`          | `src/com/sulake/habbo/navigator/HabboNavigator.as`             | Legacy navigator component             |
| `HabboNewNavigator`       | `src/com/sulake/habbo/navigator/HabboNewNavigator.as`          | New navigator (search-first)           |
| `IHabboNavigator`         | `src/com/sulake/habbo/navigator/IHabboNavigator.as`            | Legacy interface                       |
| `IHabboNewNavigator`      | `src/com/sulake/habbo/navigator/IHabboNewNavigator.as`         | New interface                          |
| `IHabboTransitionalNavigator` | `src/com/sulake/habbo/navigator/IHabboTransitionalNavigator.as` | Bridge exposed to legacy consumers while the new navigator is live |

Both components are registered by `HabboMain` — `HabboNavigatorCom` (component #15) and `HabboNewNavigatorCom` (component #35). At runtime only one of them is driving the UI; which one depends on the server's `NavigatorMetaDataEvent` payload.

## Legacy vs. New

| Aspect                | `HabboNavigator`                                   | `HabboNewNavigator`                                                 |
|-----------------------|----------------------------------------------------|----------------------------------------------------------------------|
| UI shape              | Tabbed lists of rooms per category                 | Single search box with filter pills and result blocks                |
| Search protocol       | Category-specific composers (`RoomTextSearchMessageComposer`, `PopularRoomsSearchMessageComposer`, …) | One unified `NewNavigatorSearchComposer(searchCode, filterInput)` |
| Result shape          | Flat list in `GuestRoomSearchResultEvent`          | Blocks in `NavigatorSearchResultBlocksEvent`                         |
| Caching / history     | Minimal                                            | `NavigatorCache`, `SearchContextHistoryManager`                      |
| Lifted / featured     | `OfficialRoomsEvent`                               | `NavigatorLiftedRoomsEvent` + `LiftDataContainer`                    |
| Preferences           | —                                                  | `NewNavigatorPreferencesEvent`, `CollapsedCategoriesEvent`           |
| Main view class       | `navigator/mainview/MainViewCtrl.as`               | `navigator/view/NavigatorView.as` + `navigator/view/search/`          |
| Message handler       | `navigator/IncomingMessages.as`                    | `navigator/NewIncomingMessages.as`                                    |

The new navigator is a **replacement**, not a supplement. It was rolled out behind a server flag; the legacy classes remain compiled so that old hotels/servers continue to work.

## New Navigator Data Flow

```
┌────────────┐   search     ┌──────────────────────────┐   NavigatorSearch-
│ SearchView │─────────────▶│ NewNavigatorSearchComposer│──ResultBlocksEvent─┐
└────────────┘              │   (searchCode, filter)    │                    │
                            └──────────────────────────┘                    │
                                                                             ▼
┌────────────────┐   ┌─────────────────┐   ┌─────────────────────┐   ┌──────────────┐
│ RoomEntry      │◀──│ BlockResultsView │◀──│ SearchResultContainer│◀──│ NavigatorView│
│ ElementFactory │   └─────────────────┘   └─────────────────────┘   └──────────────┘
└────────────────┘
       │
       │ click
       ▼
  HabboNavigator.tryVisitRoom(roomId)
```

- `SearchView` (`src/com/sulake/habbo/navigator/view/search/SearchView.as`) owns the text field and filter chips.
- `NavigatorView` renders `BlockResultsView` for each `SearchResultSet` in the response.
- Results are cached in `NavigatorCache` keyed by `(searchCode, filterInput)` so tab-switching doesn't re-query.

## Categories, Public Spaces, Favourites

Loaded eagerly after login:

| Composer                                      | Response                                   | Purpose                                 |
|------------------------------------------------|--------------------------------------------|-----------------------------------------|
| `GetUserFlatCatsMessageComposer`               | `UserFlatCatsEvent` (1562)                | User-room category list                 |
| `GetUserEventCatsMessageComposer`              | `UserEventCatsEvent`                       | Event categories for user-owned rooms   |
| `GetCategoriesWithUserCountMessageComposer`    | `CategoriesWithVisitorCountEvent` (1455)   | Public categories with live visitor counts |

Favourites:

- `AddFavouriteRoomMessageComposer`, `DeleteFavouriteRoomMessageComposer`
- `FavouritesEvent` (151) — full list
- `FavouriteChangedEvent` — incremental update

Legacy navigator stores these in `NavigatorData` (`_allCategories`, `_visibleCategories`, `_favouriteIds`, `_favouriteLimit`).

## Entering a Room from the Navigator

When the user clicks a room row, the navigator issues a room-forward request through the connection layer. The server responds with `RoomForwardMessageEvent` (160), which is handled by the room engine — see [Data-Flows/Room-Interactions](../Data-Flows/Room-Interactions.md) for the full enter-room sequence.

## Relevant Packets

See the [Packet Reference](../Protocol/Packet-Reference.md) for the complete list.

**Incoming — legacy navigator:**
- `FavouritesEvent` (151), `FavouriteChangedEvent`
- `OfficialRoomsEvent` — official/staff-picked rooms
- `PopularRoomTagsResultEvent`
- `GuestRoomSearchResultEvent`
- `RoomForwardMessageEvent` (160)

**Incoming — new navigator:**
- `NavigatorSearchResultBlocksEvent` — search results in blocks
- `NavigatorMetaDataEvent` — metadata + feature flags
- `NavigatorLiftedRoomsEvent` — featured rooms
- `NavigatorSavedSearchesEvent` — user's saved searches
- `NewNavigatorPreferencesEvent`
- `CollapsedCategoriesEvent` (1543)

**Incoming — categories:**
- `UserFlatCatsEvent` (1562), `UserEventCatsEvent`, `CategoriesWithVisitorCountEvent` (1455)

**Outgoing — legacy search:**
- `RoomTextSearchMessageComposer`, `PopularRoomsSearchMessageComposer`, `MyFavouriteRoomsSearchMessageComposer`
- `GetOfficialRoomsMessageComposer`, `GetPopularRoomTagsMessageComposer`

**Outgoing — new search:**
- `NewNavigatorSearchComposer`
- `NewNavigatorInitComposer`
- `GetUserFlatCatsMessageComposer`, `GetUserEventCatsMessageComposer`

**Outgoing — favourites:**
- `AddFavouriteRoomMessageComposer`, `DeleteFavouriteRoomMessageComposer`

## Cross-references

- [Data Flows / Room Interactions](../Data-Flows/Room-Interactions.md) — what happens after you click "enter"
- [Features/Messenger](Messenger.md) — room invites from friends also route through the navigator's `tryVisitRoom()`
- [Core-Systems/Room-Engine/Architecture](../Core-Systems/Room-Engine/Architecture.md) — the engine that renders the room once the navigator hands it off
- [Protocol/Packet Reference](../Protocol/Packet-Reference.md) — `navigator/` and `newnavigator/` categories
