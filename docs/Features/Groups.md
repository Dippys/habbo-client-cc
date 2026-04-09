# Groups

The Groups system (internally called "HabboGroups" or "Guilds") allows players to create, join, and manage community groups called "guilds". Each group has a badge, a home room (guild base), member management, discussion forums, and integration with the Messenger system for group chat. The implementation spans approximately 30 files under `src/com/sulake/habbo/groups/` plus related UI controllers, communication parsers, and furniture logic.

## Entry Point

| Class / Interface              | File                                                                 | Role                                               |
|--------------------------------|----------------------------------------------------------------------|----------------------------------------------------|
| `HabboGroupsManager`           | `src/com/sulake/habbo/groups/HabboGroupsManager.as`                 | Sulake `Component` — wires up window controllers, message handlers, link events |
| `IHabboGroupsManager`         | `src/com/sulake/habbo/groups/IHabboGroupsManager.as`                | Public interface for external components (room UI, catalog, toolbar) |
| `HabboGroupsManagerBootstrap` | `src/com/sulake/habbo/bootstrap/HabboGroupsManagerBootstrap.as`     | Bootstrap subclass with optional overrides       |
| `IIDHabboGroupsManager`       | `src/com/sulake/iid/IIDHabboGroupsManager.as`                        | Interface identifier for dependency injection    |

`HabboGroupsManager` is registered by `HabboMain` as component #27 (or later) in the boot order (see [Application-Lifecycle](Application-Lifecycle)). It depends on window manager, communication manager, localization, navigator, friend list, catalog, toolbar, and session data manager. The component implements `ILinkEventTracker` to handle `group/` URL links.

## Group Features

### Group Creation

1. User initiates group creation from the navigator or toolbar.
2. Client sends `GetGuildCreationInfoMessageComposer` to request group creation data.
3. Server responds with `GuildCreationInfoMessageEvent` (packet ID 2729) containing:
   - Available group name lengths
   - Max members per group type
   - Available colors and badge parts
4. Client opens the `GuildManagementWindowCtrl` in creation mode.
5. User submits `CreateGuildMessageComposer` with name, description, colors, and badge definition.
6. Server responds with `GuildCreatedMessageEvent` (packet ID 2808) containing the new group's `guildId`.
7. Client displays `GroupCreatedWindowCtrl` with success confirmation.

```actionscript
// From GroupDetailsCtrl.as:14-18
import com.sulake.habbo.communication.messages.outgoing.users.JoinHabboGroupMessageComposer;
// ...
public function onJoinGroupClick():void
{
    this._manager.send(new JoinHabboGroupMessageComposer(this._selectedGroup.groupId));
}
```

### Group Joining

Three membership states exist: `STATUS_NOT_MEMBER` (0), `STATUS_MEMBER` (1), `STATUS_PENDING` (2).

**Open groups:** User clicks "Join" → client sends `JoinHabboGroupMessageComposer` → server adds membership and replies with updated `HabboGroupDetailsMessageEvent`.

**Closed groups:** User requests join → server sets status to `STATUS_PENDING` → admin receives `GroupMembershipRequestedMessageEvent` (in `GuildMembersWindowCtrl.onMembershipRequested`). Admin approves via `GuildMembershipUpdatedMessageEvent` or rejects via `GuildMembershipRejectedMessageEvent`.

**Exclusive groups** (type `TYPE_EXCLUSIVE` = 1): Require membership request even if publicly visible.

Join is logged via `EventLogMessageComposer` (category `"HabboGroups"`, action `"join"`) — see `GroupDetailsCtrl.as:177`.

### Group Management

| Operation                    | Composer / Event                                  | Packet ID |
|------------------------------|--------------------------------------------------|-----------|
| Get group details            | `GetHabboGroupDetailsMessageComposer`            | —         |
| Get members list             | `GetGuildMembersMessageComposer`                 | —         |
| Kick member                  | `KickMemberMessageComposer`                      | —         |
| Update settings              | `UpdateGuildSettingsMessageComposer`             | —         |
| Update colors                | `UpdateGuildColorsMessageComposer`               | —         |
| Update identity (name/desc)  | `UpdateGuildIdentityMessageComposer`            | —         |
| Update badge                 | `UpdateGuildBadgeMessageComposer`               | —         |
| Deactivate (delete) group    | `DeactivateGuildMessageComposer`                | —         |
| Set favorite group           | `SelectFavouriteHabboGroupMessageComposer`       | —         |
| Remove favorite              | `DeselectFavouriteHabboGroupMessageComposer`     | —         |

The management UI lives in `GuildManagementWindowCtrl`. It uses `GuildSettingsData` to track pending changes before submission.

### Guild Base (Group Home Room)

Each group can have a dedicated "guild base" room. The base is identified by `HabboGroupDetailsData.roomId`. When users visit the base:

1. The room engine sets `RoomSession.isGuildRoom = true` (see `RoomSession.as:598`).
2. Furniture context menu gains guild-specific options via `GuildFurnitureContextMenuView`.
3. `FurnitureGuildCustomizedLogic` renders custom badge colors on furni (see `FurnitureGuildCustomizedVisualization`).
4. Users can decorate the base — member decoration rights are tracked in `HabboGroupDetailsData.membersCanDecorate`.

The navigator exposes guild base search via `GuildBaseSearchMessageComposer` and `MyGuildBasesSearchMessageComposer`.

## UI Components

`HabboGroupsManager` instantiates seven window controllers, each managing a specific UI surface:

| Controller                     | File                                                        | Purpose                                          |
|---------------------------------|-------------------------------------------------------------|--------------------------------------------------|
| `DetailsWindowCtrl`            | `src/com/sulake/habbo/groups/DetailsWindowCtrl.as`        | Main group info panel (badge, name, join button) |
| `GuildMembersWindowCtrl`       | `src/com/sulake/habbo/groups/GuildMembersWindowCtrl.as`   | Member list, join requests, kick UI             |
| `GuildManagementWindowCtrl`    | `src/com/sulake/habbo/groups/GuildManagementWindowCtrl.as` | Group settings, colors, badge editor            |
| `ExtendedProfileWindowCtrl`    | `src/com/sulake/habbo/groups/ExtendedProfileWindowCtrl.as` | Full profile view with group tab                |
| `HcRequiredWindowCtrl`         | `src/com/sulake/habbo/groups/HcRequiredWindowCtrl.as`     | "HC required" overlay for premium features      |
| `GroupCreatedWindowCtrl`       | `src/com/sulake/habbo/groups/GroupCreatedWindowCtrl.as`  | Success confirmation after group creation       |
| `GroupRoomInfoCtrl`            | `src/com/sulake/habbo/groups/GroupRoomInfoCtrl.as`        | Room info popup integration for guild bases     |

All controllers load their window XML from `HabboGroupsCom*.bin` embedded assets (see `src/images/` and `src/binaryData/`).

### Badge Editor

The badge editor is a complex multi-layer component under `src/com/sulake/habbo/groups/badge/`:

| Class                        | Purpose                                                      |
|------------------------------|--------------------------------------------------------------|
| `BadgeEditorCtrl`            | Main editor controller; manages 5 layers (`BadgeLayerCtrl`) |
| `BadgeLayerCtrl`             | Individual layer (position, item selection)                |
| `BadgeSelectPartCtrl`        | Part picker grid (shapes, symbols, etc.)                    |
| `BadgeLayerOptions`          | Per-layer options (color, offset)                          |
| `BadgeEditorPartItem`        | Grid item for a single badge part                           |

Badge data is initialized via `GuildEditorDataMessageEvent` (packet ID 2609). The editor dispatches `HabboGroupsEditorData` events when the user enters/leaves edit mode.

### Group Forums (Group Chat)

Group forums live under `src/com/sulake/habbo/friendbar/groupforums/`:

| Class                         | Purpose                                                        |
|-------------------------------|----------------------------------------------------------------|
| `GroupForumController`        | Main controller for a single group forum                    |
| `GroupForumView`             | UI view for the forum thread list                            |
| `GroupForumViewController`    | View model / logic                                            |
| `ForumsListView`             | List of all forums the user has access to                   |
| `ThreadListView`             | List of threads in a forum                                    |
| `MessageListView`            | Messages in a thread                                         |
| `ComposeMessageView`         | New thread / reply composition                               |
| `ForumData`                  | Forum metadata (name, description, unread count)             |
| `ThreadData` / `MessagesListData` | Thread/post data containers                          |

The forum system is integrated with the friend bar (see [Features/Messenger](Messenger)) and uses the following packet flow:

- `GetForumsListMessageComposer` → `ForumsListMessageEvent`
- `GetThreadsMessageComposer` → `GuildForumThreadsEvent`
- `PostThreadMessageComposer` → `PostThreadMessageEvent`
- `PostMessageMessageComposer` → `PostMessageMessageEvent`
- `UpdateThreadMessageEvent` / `UpdateMessageMessageEvent` for real-time updates
- `UnreadForumsCountMessageEvent` for the red-dot indicator

## Relevant Packets

See [Protocol/Packet Reference](Packet-Reference) for full IDs. Key packets:

**Incoming — group data:**
- `HabboGroupDetailsMessageEvent` (1702) — group info snapshot
- `GuildCreatedMessageEvent` (2808) — new group confirmation
- `GuildMembersEvent` (1200) — member list
- `GuildCreationInfoMessageEvent` (2729) — creation requirements
- `GuildEditorDataMessageEvent` (2609) — badge editor data
- `GuildEditInfoMessageEvent` — existing group data for editing
- `GroupMembershipRequestedMessageEvent` — pending join request
- `GroupDetailsChangedMessageEvent` — group updated externally

**Incoming — forums:**
- `ForumsListMessageEvent`
- `GuildForumThreadsEvent`
- `ThreadMessagesMessageEvent`
- `PostThreadMessageEvent` / `PostMessageMessageEvent`
- `UpdateThreadMessageEvent` / `UpdateMessageMessageEvent`
- `UnreadForumsCountMessageEvent`

**Outgoing:**
- `CreateGuildMessageComposer`
- `JoinHabboGroupMessageComposer`
- `GetHabboGroupDetailsMessageComposer`
- `GetGuildMembersMessageComposer`
- `KickMemberMessageComposer`
- `UpdateGuildSettingsMessageComposer`
- `UpdateGuildColorsMessageComposer`
- `UpdateGuildIdentityMessageComposer`
- `UpdateGuildBadgeMessageComposer`
- `DeactivateGuildMessageComposer`
- `SelectFavouriteHabboGroupMessageComposer` / `DeselectFavouriteHabboGroupMessageComposer`

**Outgoing — forums:**
- `GetForumsListMessageComposer`
- `GetThreadsMessageComposer`
- `PostThreadMessageComposer`
- `PostMessageMessageComposer`
- `GetMessagesMessageComposer`
- `ModerateThreadMessageComposer` / `ModerateMessageMessageComposer`

## Cross-references

- [Features/Messenger](Messenger) — group forums are embedded in the friend bar; group chat is initiated from the group context.
- [Features/Inventory/Badges](Inventory#badges) — group badges are rendered using the same `IBadgeImageWidget` infrastructure as user badges; `UserBadgesEvent` includes group badges.
- [Core-Systems/Furniture-System/Architecture](Core-Systems/Furniture-System/Architecture) — guild base furniture uses `FurnitureGuildCustomizedLogic` for badge/color rendering; context menu integration via `GuildFurnitureContextMenuView`.
- [Protocol/Packet Reference](Packet-Reference) — complete guild and forum packet ID list.

## Key Files

| File                                                                              | Purpose                                      |
|-----------------------------------------------------------------------------------|----------------------------------------------|
| `src/com/sulake/habbo/groups/HabboGroupsManager.as`                               | Main component, message routing             |
| `src/com/sulake/habbo/groups/IHabboGroupsManager.as`                             | Public interface                            |
| `src/com/sulake/habbo/groups/GroupDetailsCtrl.as`                                | Group info window controller                |
| `src/com/sulake/habbo/groups/GuildMembersWindowCtrl.as`                          | Member list and management                  |
| `src/com/sulake/habbo/groups/GuildManagementWindowCtrl.as`                       | Group settings and creation UI              |
| `src/com/sulake/habbo/groups/badge/BadgeEditorCtrl.as`                           | Badge editor main controller                |
| `src/com/sulake/habbo/friendbar/groupforums/GroupForumController.as`            | Group forum controller                      |
| `src/com/sulake/habbo/communication/messages/incoming/users/HabboGroupDetailsData.as` | Group data structure              |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureGuildCustomizedLogic.as` | Guild furni rendering logic        |
| `src/com/sulake/habbo/session/RoomSession.as`                                    | `isGuildRoom` property for guild bases      |