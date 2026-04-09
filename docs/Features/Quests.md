# Quests & Achievements

The quest engine covers two loosely-coupled reward systems: **quests** (finite, time-bound objectives handed to the player) and **achievements** (persistent progress badges that accumulate forever). They live in the same package because they share the toolbar button, the resolution pop-up, and the same underlying component lifecycle — but they use entirely different data models and packets.

## Entry Point

| Class / Interface               | File                                                         | Role                                                        |
|---------------------------------|--------------------------------------------------------------|-------------------------------------------------------------|
| `HabboQuestEngine`              | `src/com/sulake/habbo/quest/HabboQuestEngine.as`             | Sulake `Component`, implements `IUpdateReceiver` for frame ticks |
| `QuestController`               | `src/com/sulake/habbo/quest/QuestController.as`               | Active quest state, panel display, quest actions             |
| `AchievementController`         | `src/com/sulake/habbo/quest/AchievementController.as`         | Achievement categories, progress, badge list                 |
| `AchievementsResolutionController` | `src/com/sulake/habbo/quest/AchievementsResolutionController.as` | Pop-up dialogs when an achievement is earned or progressed |

Registered by `HabboMain` as `HabboQuestEngineCom` (component #30; see [Application Lifecycle](../Architecture/Application-Lifecycle.md)).

## Quests

### Data Model

A quest is represented by `QuestMessageData` (`src/com/sulake/habbo/communication/messages/incoming/quest/QuestMessageData.as`):

| Field / Getter       | Meaning                                            |
|----------------------|----------------------------------------------------|
| `id`                 | Server-assigned quest id                           |
| `type`               | Category string (explore, shop, decorate, etc.)    |
| `accepted`           | Has the user accepted it?                          |
| `activityPointType`  | Reward currency type                               |
| `localizationCode`   | Key prefix for quest title / description strings   |
| current / total steps | Progress counters (obfuscated field names)        |
| rewardAmount / rewardType | What you get on completion                    |
| secondsRemaining     | Countdown timer for time-limited quests            |
| `easy`               | Difficulty flag                                    |
| isComplete / rewardAvailable | Computed helpers                           |

Localized title and description are built via two helpers on the same class that combine `localizationCode` with the quest type.

### Quest Variants

All variants ride the same `QuestMessageData` shape but arrive on different packets so the UI can route them to different tabs:

| Variant           | Incoming packet                            | Notes                                                                 |
|-------------------|--------------------------------------------|-----------------------------------------------------------------------|
| Regular quests    | `QuestsMessageEvent`                       | Array of quests                                                       |
| Daily quest       | `QuestDailyMessageEvent`                   | Single quest refreshed every 24h                                     |
| Seasonal quests   | `SeasonalQuestsMessageEvent` (1122)        | Bundled with a calendar UI under `src/com/sulake/habbo/quest/seasonalcalendar/` |
| Single quest update| `QuestMessageEvent`                       | Push-update for one quest                                             |
| Cancelled         | `QuestCancelledMessageEvent`               | Server cancelled your quest                                           |
| Completed         | `QuestCompletedMessageEvent`               | Triggers a resolution pop-up                                          |

The **seasonal calendar** is a distinct mini-UI (`seasonalcalendar/MainWindow.as`, `Calendar.as`, `CatalogPromo.as`, `RareTeaser.as`) shown around real-world holidays.

### Community Goals

Community goals are collective progress events — everyone on the hotel contributes to a shared target. Handled by the quest engine but modelled separately:

- `CommunityGoalData` — personal contribution, community total, level, time remaining
- `CommunityGoalProgressMessageEvent` (push updates)
- `CommunityGoalEarnedPrizesMessageEvent` (redeem UI)
- `CommunityGoalHallOfFameMessageEvent` (top contributors)
- `CommunityGoalVoteMessageEvent` (1435) — voting stages
- `ConcurrentUsersGoalProgressMessageEvent` — live-count-triggered goals

## Achievements

Achievements are **not** in the quest package for packet purposes — their messages live under `src/com/sulake/habbo/communication/messages/incoming/inventory/achievements/`. They're grouped here because the **controller** is part of the quest engine component.

### Data Model

`Achievement` (also in `inventory/achievements/`):

| Field             | Meaning                                        |
|-------------------|------------------------------------------------|
| `achievementId`   | Unique id                                      |
| `level`           | Current level (achievements are tiered)        |
| `badgeId`         | Badge to display when earned                   |
| `category`        | Category bucket for UI grouping                |
| currentPoints     | Progress toward next level                     |
| pointsPerLevel    | Threshold for next level                       |
| `isSecret`        | Hidden until earned                            |

Achievement **state** is one of:

| State           | Meaning                    |
|-----------------|----------------------------|
| Undefined       | Unknown / no data          |
| Not started     | Visible but no progress    |
| In progress     | Has partial progress       |
| Completed       | Fully earned at all tiers  |

These are defined as obfuscated constants in `AchievementController.as`.

### Controllers

| Controller                         | Responsibility                                                     |
|------------------------------------|--------------------------------------------------------------------|
| `AchievementController`            | Category list, progress bars, badge rendering, unseen count       |
| `AchievementsResolutionController` | Pop-up dialogs when an achievement ticks or completes              |
| `AchievementResolutionCompletedView`| "You earned X!" celebration view                                  |
| `AchievementResolutionProgressView` | "+1 progress toward Y" transient view                             |
| `AchievementCategory` / `AchievementCategories` | Category tabs in the main achievement window          |

## Relevant Packets

See the [Packet Reference](../Protocol/Packet-Reference.md) for the complete list under `quest/`, `inventory/achievements/`, and related categories.

**Incoming — quests:**
- `QuestsMessageEvent`
- `QuestMessageEvent`
- `QuestDailyMessageEvent`
- `SeasonalQuestsMessageEvent` (1122)
- `QuestCompletedMessageEvent`
- `QuestCancelledMessageEvent`
- `EpicPopupMessageEvent`

**Incoming — community goals:**
- `CommunityGoalProgressMessageEvent`
- `CommunityGoalEarnedPrizesMessageEvent`
- `CommunityGoalHallOfFameMessageEvent`
- `CommunityGoalVoteMessageEvent` (1435)
- `ConcurrentUsersGoalProgressMessageEvent`

**Incoming — achievements:**
- `AchievementsEvent`
- `AchievementEvent`
- `UnseenAchievementsCountUpdateEvent`

**Outgoing — quests:**
- `GetQuestsMessageComposer`
- `GetDailyQuestMessageComposer`
- `GetSeasonalQuestsOnlyMessageComposer`
- `AcceptQuestMessageComposer`
- `ActivateQuestMessageComposer`
- `RejectQuestMessageComposer`
- `CancelQuestMessageComposer`
- `FriendRequestQuestCompleteMessageComposer`
- `OpenQuestTrackerMessageComposer`
- `StartCampaignMessageComposer`

**Outgoing — community goals:**
- `GetCommunityGoalProgressMessageComposer`
- `GetCommunityGoalEarnedPrizesMessageComposer`
- `GetCommunityGoalHallOfFameMessageComposer`
- `RedeemCommunityGoalPrizeMessageComposer`
- `GetConcurrentUsersRewardMessageComposer`
- `GetConcurrentUsersGoalProgressMessageComposer`

**Outgoing — achievements:**
- `GetAchievementsComposer`

## Cross-references

- [Features/Catalog](Catalog.md) — community-goal prizes are delivered through a dedicated catalog page
- [Features/Inventory](Inventory.md) — achievement badges end up in the badges inventory
- [Architecture/Application Lifecycle](../Architecture/Application-Lifecycle.md) — where the quest engine is registered at boot
- [Protocol/Packet Reference — quest](../Protocol/Packet-Reference.md) — complete quest / achievement ID tables
