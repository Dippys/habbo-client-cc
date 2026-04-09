# Messenger

The messenger is the private-chat system: instant messages between friends, offline/stored messages, and room invites. It's a small package (~8 files) because it leans heavily on the friend-list component for both data and UI.

## Entry Point

| Class / Interface   | File                                                         | Role                                                    |
|---------------------|--------------------------------------------------------------|---------------------------------------------------------|
| `HabboMessenger`    | `src/com/sulake/habbo/messenger/HabboMessenger.as`           | Sulake `Component`. Queues incoming messages, owns the main window, pumps a batch timer |
| `IHabboMessenger`   | `src/com/sulake/habbo/messenger/IHabboMessenger.as`          | Public interface — `openChat(friendId)`, `sendMessage(...)`, etc. |
| `MainView`          | `src/com/sulake/habbo/messenger/MainView.as`                 | The chat window UI                                      |
| `ChatEntry`         | `src/com/sulake/habbo/messenger/ChatEntry.as`                | A single rendered message (own / other / notification) |
| `ChatQueueEntry`    | `src/com/sulake/habbo/messenger/ChatQueueEntry.as`            | A pending message waiting to be rendered in the next batch tick |

Registered by `HabboMain` as `HabboMessengerCom` (component #17; see [Application Lifecycle](../Architecture/Application-Lifecycle.md)).

## Dependency on Friend List

Messenger does **not** own friend data. It receives `IHabboFriendsList` via component dependency injection (`IIDHabboFriendList`) and looks up avatar, online state, and figure strings from there.

| Class                       | File                                                           |
|-----------------------------|----------------------------------------------------------------|
| `HabboFriendList`           | `src/com/sulake/habbo/friendlist/HabboFriendList.as`            |
| `IHabboFriendsList`         | `src/com/sulake/habbo/friendlist/IHabboFriendsList.as`          |
| `Friend`                    | `src/com/sulake/habbo/friendlist/domain/Friend.as`              |
| `FriendCategories`          | `src/com/sulake/habbo/friendlist/domain/FriendCategories.as`    |

When the friend list publishes a `FriendListUpdateEvent`, messenger forwards online/offline status changes to any open chat tab so presence indicators stay live.

## Message Flow

```
User types in MainView
        │
        ▼
HabboMessenger.sendMessage(friendId, text)
        │
        ▼
new SendMsgMessageComposer(friendId, text)
        │
        ▼
connection.send(...)                          [client → server]
        │
        ▼ (routed by server)
┌──────────────────────┐
│ Recipient's client   │
│                      │
│ NewConsoleMessage    │◀── NewConsoleMessageMessageParser
│ Event                │
└──────────┬───────────┘
           │
           ▼
HabboMessenger._messageEvents.push(...)       [batch queue]
           │
           ▼
 _batchUpdatingTimer tick
           │
           ▼
MainView appends ChatEntry to conversation
```

**Why batch?** Incoming messages can arrive in bursts (friend sends multiple lines, or several friends message at once). `HabboMessenger` queues them into `_messageEvents` and flushes on a timer so the UI doesn't re-layout per-message.

### Errors

The server validates every `SendMsgMessageComposer`. On failure it returns `InstantMessageErrorEvent` with an error code:

| Code | Meaning                           | Localization key                  |
|------|-----------------------------------|-----------------------------------|
| 3    | Not a friend                      | `"${messenger.error.not_friend}"` |
| 4    | Muted by server / moderation     | `"${messenger.error.muted}"`      |
| 5    | Target offline (store-and-forward failed) | `"${messenger.error.offline}"` |
| 6    | No chat access                    | `"${messenger.error.no_access}"`  |
| 10   | Target offline and offline store failed | `"${messenger.error.offline_failed}"` |

The exact values live in `MainView.as` as localization lookups.

## Offline Messages

If a recipient is offline, the server stores the message and delivers it on next login as a **regular** `NewConsoleMessageEvent` — there is no dedicated "offline message" packet. The client doesn't need to do anything special; messages just appear in the next session. `MiniMailNewMessageEvent` exists separately and is used for the older in-game email / mini-mail system.

## Data Structures

- `MainView._chatEntries` — `Dictionary` keyed by friend ID → array of `ChatEntry` for that conversation.
- `HabboMessenger._messageEvents` — `Vector` of pending events waiting for the next batch tick.
- `HabboMessenger._batchUpdatingTimer` — short-interval `Timer` that drains `_messageEvents`.

## Relevant Packets

See the [Packet Reference](../Protocol/Packet-Reference.md). Messenger shares the `friendlist/` message category.

**Incoming (friendlist):**
- `MessengerInitEvent` — on login: friends list, categories, chat settings
- `NewConsoleMessageEvent` (1587) — instant message received (also used for offline delivery)
- `InstantMessageErrorEvent` — delivery failure
- `RoomInviteEvent` — friend invites you to their room
- `FriendListUpdateEvent` — friend online/offline/status change
- `FriendListFragmentEvent` — paginated friend list on boot
- `MiniMailNewMessageEvent` — legacy in-game mail

**Outgoing (friendlist):**
- `MessengerInitMessageComposer` — requested during login
- `SendMsgMessageComposer(friendId, text)` — send an IM
- `SendRoomInviteMessageComposer` — invite friend to your room

## Cross-references

- [Features/Navigator](Navigator.md) — clicking a room invite routes through `HabboNavigator.tryVisitRoom()`
- [Data Flows / Client-Server Communication](../Data-Flows/Client-Server-Communication.md) — the connection and dispatch layer messenger sits on
- [Protocol/Packet Reference — friendlist](../Protocol/Packet-Reference.md) — complete list of messaging/friend packets
- [Features/Inventory — trading](Inventory.md) — trading uses friend identity resolution too
