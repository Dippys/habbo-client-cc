# Packet Reference

This page is a categorized index of **every packet** the client knows about. It was generated from `src/com/sulake/habbo/communication/HabboMessages.as` — the single source of truth that maps integer message IDs to ActionScript event and composer classes.

For the byte layout of any frame, see [Wire Format](Wire-Format). For the class pattern behind each row, see [Message Pattern](Message-Pattern). For the handshake packets (IDs 1347, 3885, 773, 4000), see [Encryption](Encryption).

## Totals

| Direction | Count | Registry source                                       |
|-----------|-------|-------------------------------------------------------|
| Incoming  | 502   | `HabboMessages.as` — `INCOMING_PACKETS` (line 991)    |
| Outgoing  | 494   | `HabboMessages.as` — `OUTGOING_PACKETS` (line 992)    |
| **Total** | **996** |                                                     |

(A few additional message class files exist in the `messages/` tree that are not registered in `HabboMessages.as` and therefore cannot be sent or received. They're omitted here.)

## How to use this reference

- Each row shows `ID | Class`. Click or grep the class name to find the AS3 source.
- Incoming classes live in `src/com/sulake/habbo/communication/messages/incoming/<category>/` (and in `snowwar/…` for the SnowWar mini-game).
- Incoming **parsers** (the byte readers) live in a parallel tree: `src/com/sulake/habbo/communication/messages/parser/<category>/`. So `FurniListAddOrUpdateEvent` has its wire layout defined in `parser/inventory/furni/FurniListAddOrUpdateParser.as`.
- Outgoing classes live in `src/com/sulake/habbo/communication/messages/outgoing/<category>/`.
- To look up a specific ID, search `HabboMessages.as` directly: e.g. `grep -n "INCOMING_PACKETS\[1347\]" src/com/sulake/habbo/communication/HabboMessages.as`.

## Notable IDs

A few packets worth knowing by heart:

| ID    | Direction | Class                                        | Phase / Use          |
|-------|-----------|----------------------------------------------|----------------------|
| 4000  | OUT       | `ClientHelloMessageComposer`                 | Handshake step 1     |
| 1347  | IN        | `InitDiffieHandshakeEvent`                   | Server DH parameters |
| 773   | OUT       | `CompleteDiffieHandshakeMessageComposer`     | Client DH pubkey     |
| 3885  | IN        | `CompleteDiffieHandshakeEvent`               | Server DH pubkey, enables RC4 |
| 10    | IN        | `LatencyPingResponseMessageEvent`            | Ping response        |

See [Encryption](Encryption) for the handshake walkthrough.

## Categories

The tables below are sorted first by direction (Incoming / Outgoing), then by category (the `messages/<direction>/<category>/` subfolder), then by numeric ID. Categories prefixed `snowwar:` are part of the SnowWar mini-game shipped in a separate `src/snowwar/` package tree.

---

## Incoming Packets

### advertisement

| ID | Class |
|----|-------|
| 1759 | `RoomAdErrorEvent` |
| 1808 | `InterstitialMessageEvent` |

### availability

| ID | Class |
|----|-------|
| 600 | `AvailabilityTimeMessageEvent` |
| 1050 | `HotelWillCloseInMinutesEvent` |
| 1350 | `MaintenanceStatusMessageEvent` |
| 2033 | `AvailabilityStatusMessageEvent` |
| 2771 | `HotelClosesAndWillOpenAtEvent` |
| 3728 | `HotelClosedAndOpensEvent` |

### avatar

| ID | Class |
|----|-------|
| 118 | `ChangeUserNameResultMessageEvent` |
| 563 | `CheckUserNameResultMessageEvent` |
| 2429 | `FigureUpdateEvent` |
| 3315 | `WardrobeMessageEvent` |

### bots

| ID | Class |
|----|-------|
| 233 | `BotRemovedFromInventoryEvent` |
| 1352 | `BotAddedToInventoryEvent` |
| 3086 | `BotInventoryEvent` |
| 3684 | `BotReceivedMessageEvent` |

### callforhelp

| ID | Class |
|----|-------|
| 325 | `CfhTopicsInitEvent` |
| 2221 | `SanctionStatusEvent` |
| 2782 | `CfhSanctionMessageEvent` |

### camera

| ID | Class |
|----|-------|
| 133 | `CompetitionStatusMessageEvent` |
| 2057 | `CameraPublishStatusMessageEvent` |
| 2783 | `CameraPurchaseOKMessageEvent` |
| 3595 | `ThumbnailStatusMessageEvent` |
| 3696 | `CameraStorageUrlMessageEvent` |
| 3878 | `InitCameraMessageEvent` |

### campaign

| ID | Class |
|----|-------|
| 2531 | `CampaignCalendarDataMessageEvent` |
| 2551 | `CampaignCalendarDoorOpenedMessageEvent` |

### catalog

| ID | Class |
|----|-------|
| 44 | `LimitedOfferAppearingNextMessageEvent` |
| 119 | `TargetedOfferEvent` |
| 195 | `DirectSMSClubBuyAvailableMessageEvent` |
| 377 | `LimitedEditionSoldOutEvent` |
| 619 | `ClubGiftInfoEvent` |
| 659 | `ClubGiftSelectedEvent` |
| 714 | `VoucherRedeemErrorMessageEvent` |
| 761 | `IsOfferGiftableMessageEvent` |
| 804 | `CatalogPageMessageEvent` |
| 869 | `PurchaseOKMessageEvent` |
| 1032 | `CatalogPagesListEvent` |
| 1237 | `TargetedOfferNotFoundEvent` |
| 1404 | `PurchaseErrorMessageEvent` |
| 1452 | `BuildersClubSubscriptionStatusMessageEvent` |
| 1517 | `GiftReceiverNotFoundEvent` |
| 1533 | `BonusRareInfoMessageEvent` |
| 1866 | `CatalogPublishedMessageEvent` |
| 1889 | `SeasonalCalendarDailyOfferMessageEvent` |
| 2234 | `GiftWrappingConfigurationEvent` |
| 2347 | `BundleDiscountRulesetMessageEvent` |
| 2405 | `HabboClubOffersMessageEvent` |
| 2468 | `RoomAdPurchaseInfoEvent` |
| 2515 | `CatalogPageWithEarliestExpiryMessageEvent` |
| 2668 | `CatalogPageExpirationEvent` |
| 3331 | `SellablePetPalettesMessageEvent` |
| 3336 | `VoucherRedeemOkMessageEvent` |
| 3388 | `ProductOfferEvent` |
| 3770 | `PurchaseNotAllowedMessageEvent` |
| 3828 | `BuildersClubFurniCountMessageEvent` |
| 3914 | `NotEnoughBalanceMessageEvent` |
| 3964 | `HabboClubExtendOfferMessageEvent` |
| 5210 | `FireworkChargeDataEvent` |

### competition

| ID | Class |
|----|-------|
| 1177 | `CompetitionEntrySubmitResultEvent` |
| 1745 | `CurrentTimingCodeMessageEvent` |
| 2064 | `NoOwnedRoomsAlertMessageEvent` |
| 3506 | `CompetitionVotingInfoMessageEvent` |
| 3841 | `IsUserPartOfCompetitionMessageEvent` |
| 3926 | `SecondsUntilMessageEvent` |

### crafting

| ID | Class |
|----|-------|
| 618 | `CraftingResultEvent` |
| 1000 | `CraftableProductsEvent` |
| 2124 | `CraftingRecipesAvailableEvent` |
| 2774 | `CraftingRecipeEvent` |

### error

| ID | Class |
|----|-------|
| 1004 | `ErrorReportEvent` |

### friendfurni

| ID | Class |
|----|-------|
| 382 | `FriendFurniOtherLockConfirmedMessageEvent` |
| 770 | `FriendFurniCancelLockMessageEvent` |
| 3753 | `FriendFurniStartConfirmationMessageEvent` |

### friendlist

| ID | Class |
|----|-------|
| 280 | `FriendRequestsEvent` |
| 462 | `RoomInviteErrorEvent` |
| 892 | `MessengerErrorEvent` |
| 896 | `AcceptFriendResultEvent` |
| 973 | `HabboSearchResultEvent` |
| 1210 | `FindFriendsProcessResultEvent` |
| 1587 | `NewConsoleMessageEvent` |
| 1605 | `MessengerInitEvent` |
| 1911 | `MiniMailNewMessageEvent` |
| 2219 | `NewFriendRequestEvent` |
| 2800 | `FriendListUpdateEvent` |
| 2803 | `MiniMailUnreadCountEvent` |
| 3048 | `FollowFriendFailedEvent` |
| 3082 | `FriendNotificationEvent` |
| 3130 | `FriendListFragmentMessageEvent` |
| 3359 | `InstantMessageErrorEvent` |
| 3870 | `RoomInviteEvent` |

### game/directory

| ID | Class |
|----|-------|
| 416 | `_Str_17054` |
| 872 | `Game2InArenaQueueMessageEvent` |
| 1660 | `_Str_16258` |
| 1730 | `Game2JoiningGameFailedMessageEvent` |
| 1982 | `_Str_17148` |
| 2142 | `Game2StartingGameFailedMessageEvent` |
| 2246 | `Game2GameDirectoryStatusMessageEvent` |
| 2893 | `Game2AccountGameStatusMessageEvent` |
| 3138 | `Game2UserLeftGameMessageEvent` |
| 3191 | `Game2StopCounterMessageEvent` |
| 3915 | `_Str_15952` |

### game/lobby

| ID | Class |
|----|-------|
| 66 | `AchievementResolutionsMessageEvent` |
| 222 | `GameListMessageEvent` |
| 740 | `AchievementResolutionCompletedMessageEvent` |
| 904 | `GameInviteMessageEvent` |
| 1477 | `LeftQueueMessageEvent` |
| 1689 | `GameAchievementsMessageEvent` |
| 1715 | `UnloadGameMessageEvent` |
| 2260 | `JoinedQueueMessageEvent` |
| 2265 | `UserGameAchievementsMessageEvent` |
| 2624 | `LoadGameUrlMessageEvent` |
| 3035 | `JoiningQueueFailedMessageEvent` |
| 3370 | `AchievementResolutionProgressMessageEvent` |
| 3654 | `LoadGameMessageEvent` |
| 3805 | `GameStatusMessageEvent` |

### game/score

| ID | Class |
|----|-------|
| 2196 | `Game2WeeklyLeaderboardEvent` |
| 2270 | `Game2WeeklyFriendsLeaderboardEvent` |
| 2641 | `WeeklyGameRewardEvent` |
| 3097 | `WeeklyGameRewardWinnersEvent` |
| 3099 | `_Str_16667` |
| 3512 | `WeeklyCompetitiveLeaderboardEvent` |
| 3560 | `WeeklyCompetitiveFriendsLeaderboardEvent` |
| 3863 | `_Str_18906` |

### gifts

| ID | Class |
|----|-------|
| 91 | `TryVerificationCodeResultMessageEvent` |
| 800 | `TryPhoneNumberResultMessageEvent` |
| 2890 | `PhoneCollectionStateMessageEvent` |

### groupforums

| ID | Class |
|----|-------|
| 324 | `UpdateMessageMessageEvent` |
| 509 | `ThreadMessagesMessageEvent` |
| 1073 | `GuildForumThreadsEvent` |
| 1862 | `PostThreadMessageEvent` |
| 2049 | `PostMessageMessageEvent` |
| 2379 | `UnreadForumsCountMessageEvent` |
| 2528 | `UpdateThreadMessageEvent` |
| 3001 | `ForumsListMessageEvent` |
| 3011 | `ForumDataMessageEvent` |

### handshake

| ID | Class |
|----|-------|
| 411 | `UserRightsMessageEvent` |
| 793 | `IsFirstLoginOfDayEvent` |
| 1347 | `InitDiffieHandshakeEvent` |
| 1488 | `UniqueMachineIDEvent` |
| 1600 | `GenericErrorEvent` |
| 2491 | `AuthenticationOKMessageEvent` |
| 2725 | `UserObjectEvent` |
| 3523 | `IdentityAccountsEvent` |
| 3738 | `NoobnessLevelMessageEvent` |
| 3885 | `CompleteDiffieHandshakeEvent` |
| 3928 | `PingMessageEvent` |
| 4000 | `DisconnectReasonEvent` |

### help

| ID | Class |
|----|-------|
| 30 | `ChatReviewSessionDetachedMessageEvent` |
| 77 | `CallForHelpPendingCallsDeletedMessageEvent` |
| 138 | `GuideSessionDetachedMessageEvent` |
| 143 | `ChatReviewSessionStartedMessageEvent` |
| 219 | `GuideSessionInvitedToGuideRoomMessageEvent` |
| 673 | `GuideSessionErrorMessageEvent` |
| 735 | `ChatReviewSessionOfferedToGuideMessageEvent` |
| 841 | `GuideSessionMessageMessageEvent` |
| 934 | `IssueCloseNotificationMessageEvent` |
| 1016 | `GuideSessionPartnerIsTypingMessageEvent` |
| 1121 | `CallForHelpPendingCallsMessageEvent` |
| 1456 | `GuideSessionEndedMessageEvent` |
| 1548 | `GuideOnDutyStatusMessageEvent` |
| 1551 | `FaqSearchResultsMessageEvent` |
| 1591 | `GuideSessionAttachedMessageEvent` |
| 1651 | `CallForHelpDisabledNotifyMessageEvent` |
| 1663 | `HotelMergeNameChangeEvent` |
| 1829 | `ChatReviewSessionVotingStatusMessageEvent` |
| 1847 | `GuideSessionRequesterRoomMessageEvent` |
| 2494 | `FaqClientFaqsMessageEvent` |
| 2674 | `GuideTicketResolutionMessageEvent` |
| 2756 | `FaqCategoriesMessageEvent` |
| 2772 | `QuizResultsMessageEvent` |
| 2819 | `FaqCategoryMessageEvent` |
| 2927 | `QuizDataMessageEvent` |
| 3209 | `GuideSessionStartedMessageEvent` |
| 3276 | `ChatReviewSessionResultsMessageEvent` |
| 3285 | `GuideTicketCreationResultMessageEvent` |
| 3292 | `FaqTextMessageEvent` |
| 3463 | `GuideReportingStatusMessageEvent` |
| 3635 | `CallForHelpResultMessageEvent` |
| 3796 | `CallForHelpReplyMessageEvent` |

### inventory/achievements

| ID | Class |
|----|-------|
| 305 | `AchievementsEvent` |
| 1968 | `AchievementsScoreEvent` |
| 2107 | `AchievementEvent` |

### inventory/avatareffect

| ID | Class |
|----|-------|
| 340 | `AvatarEffectsMessageEvent` |
| 1959 | `AvatarEffectActivatedMessageEvent` |
| 2228 | `AvatarEffectExpiredMessageEvent` |
| 2867 | `AvatarEffectAddedMessageEvent` |
| 3473 | `AvatarEffectSelectedMessageEvent` |

### inventory/badges

| ID | Class |
|----|-------|
| 717 | `BadgesEvent` |
| 2493 | `BadgeReceivedEvent` |
| 2501 | `BadgePointLimitsEvent` |
| 2998 | `IsBadgeRequestFulfilledEvent` |

### inventory/clothes

| ID | Class |
|----|-------|
| 1437 | `_Str_17532` |
| 1450 | `FigureSetIdsEvent` |
| 2313 | `_Str_16135` |

### inventory/furni

| ID | Class |
|----|-------|
| 104 | `FurniListAddOrUpdateEvent` |
| 159 | `FurniListRemoveEvent` |
| 994 | `FurniListEvent` |
| 1501 | `PostItPlacedEvent` |
| 3151 | `FurniListInvalidateEvent` |

### inventory/pets

| ID | Class |
|----|-------|
| 634 | `ConfirmBreedingRequestEvent` |
| 1111 | `PetReceivedMessageEvent` |
| 1625 | `ConfirmBreedingResultEvent` |
| 1746 | `PetBreedingEvent` |
| 2101 | `PetAddedToInventoryEvent` |
| 2527 | `NestBreedingSuccessEvent` |
| 2621 | `GoToBreedingNestFailureEvent` |
| 3253 | `PetRemovedFromInventoryEvent` |
| 3522 | `PetInventoryEvent` |

### inventory/trading

| ID | Class |
|----|-------|
| 217 | `TradingOpenFailedEvent` |
| 1001 | `TradingCompletedEvent` |
| 1254 | `TradingOtherNotAllowedEvent` |
| 1373 | `TradingCloseEvent` |
| 2024 | `TradingItemListEvent` |
| 2505 | `TradingOpenEvent` |
| 2568 | `TradingAcceptEvent` |
| 2720 | `TradingConfirmationEvent` |
| 2873 | `TradingNoSuchItemEvent` |
| 3058 | `TradingYouAreNotAllowedEvent` |
| 3128 | `TradingNotOpenEvent` |

### landingview

| ID | Class |
|----|-------|
| 286 | `PromoArticlesMessageEvent` |

### landingview/votes

| ID | Class |
|----|-------|
| 1435 | `CommunityGoalVoteMessageEvent` |

### marketplace

| ID | Class |
|----|-------|
| 54 | `MarketplaceCanMakeOfferResult` |
| 680 | `MarketPlaceOffersEvent` |
| 725 | `MarketplaceItemStatsEvent` |
| 1359 | `MarketplaceMakeOfferResult` |
| 1823 | `MarketplaceConfigurationEvent` |
| 2032 | `MarketplaceBuyOfferResultEvent` |
| 3264 | `MarketplaceCancelOfferResultEvent` |
| 3884 | `MarketPlaceOwnOffersEvent` |

### moderation

| ID | Class |
|----|-------|
| 607 | `CfhChatlogEvent` |
| 1333 | `ModeratorRoomInfoEvent` |
| 1576 | `ModeratorToolPreferencesEvent` |
| 1683 | `UserBannedMessageEvent` |
| 1752 | `RoomVisitsEvent` |
| 1890 | `ModeratorCautionEvent` |
| 2030 | `ModeratorMessageEvent` |
| 2335 | `ModeratorActionResultMessageEvent` |
| 2696 | `ModeratorInitMessageEvent` |
| 2866 | `ModeratorUserInfoEvent` |
| 3150 | `IssuePickFailedMessageEvent` |
| 3192 | `IssueDeletedMessageEvent` |
| 3377 | `UserChatlogEvent` |
| 3434 | `RoomChatlogEvent` |
| 3609 | `IssueInfoMessageEvent` |

### mysterybox

| ID | Class |
|----|-------|
| 596 | `_Str_7433` |
| 2833 | `MysteryBoxKeysMessageEvent` |
| 3201 | `_Str_7564` |
| 3712 | `GotMysteryBoxPrizeMessageEvent` |

### navigator

| ID | Class |
|----|-------|
| 52 | `GuestRoomSearchResultEvent` |
| 151 | `FavouritesEvent` |
| 378 | `CanCreateRoomEvent` |
| 482 | `RoomRatingEvent` |
| 687 | `GetGuestRoomResultEvent` |
| 878 | `FlatAccessDeniedMessageEvent` |
| 1304 | `FlatCreatedEvent` |
| 1331 | `ConvertedRoomIdEvent` |
| 1455 | `CategoriesWithVisitorCountEvent` |
| 1562 | `UserFlatCatsEvent` |
| 1840 | `RoomEventEvent` |
| 1927 | `RoomThumbnailUpdateResultEvent` |
| 2012 | `PopularRoomTagsResultEvent` |
| 2309 | `DoorbellMessageEvent` |
| 2524 | `FavouriteChangedEvent` |
| 2599 | `CanCreateRoomEventEvent` |
| 2726 | `OfficialRoomsEvent` |
| 2875 | `NavigatorSettingsEvent` |
| 3244 | `UserEventCatsEvent` |
| 3297 | `RoomInfoUpdatedEvent` |
| 3479 | `RoomEventCancelEvent` |
| 3954 | `CompetitionRoomsDataMessageEvent` |

### newnavigator

| ID | Class |
|----|-------|
| 518 | `NewNavigatorPreferencesEvent` |
| 1543 | `CollapsedCategoriesEvent` |
| 2690 | `NavigatorSearchResultBlocksEvent` |
| 3052 | `NavigatorMetaDataEvent` |
| 3104 | `NavigatorLiftedRoomsEvent` |
| 3984 | `NavigatorSavedSearchesEvent` |

### notifications

| ID | Class |
|----|-------|
| 426 | `RestoreClientMessageEvent` |
| 806 | `HabboAchievementNotificationMessageEvent` |
| 859 | `PetLevelNotificationEvent` |
| 1787 | `ElementPointerMessageEvent` |
| 1992 | `NotificationDialogMessageEvent` |
| 2018 | `ActivityPointsMessageEvent` |
| 2035 | `MOTDNotificationEvent` |
| 2103 | `UnseenItemsEvent` |
| 2125 | `OfferRewardDeliveredMessageEvent` |
| 2188 | `ClubGiftNotificationEvent` |
| 2275 | `HabboActivityPointNotificationMessageEvent` |
| 3284 | `InfoFeedEnableMessageEvent` |
| 3801 | `HabboBroadcastMessageEvent` |
| 5100 | `SimpleAlertMessageEvent` |

### nux

| ID | Class |
|----|-------|
| 3575 | `NewUserExperienceGiftOfferEvent` |
| 3639 | `NewUserExperienceNotCompleteEvent` |

### perk

| ID | Class |
|----|-------|
| 2278 | `CitizenshipVipOfferPromoEnabledEvent` |
| 2586 | `PerkAllowancesEvent` |

### poll

| ID | Class |
|----|-------|
| 662 | `PollErrorEvent` |
| 1066 | `QuestionFinishedEvent` |
| 2589 | `QuestionAnsweredEvent` |
| 2665 | `QuestionEvent` |
| 2997 | `PollContentsEvent` |
| 3785 | `PollOfferEvent` |

### preferences

| ID | Class |
|----|-------|
| 513 | `AccountPreferencesEvent` |

### quest

| ID | Class |
|----|-------|
| 230 | `QuestMessageEvent` |
| 949 | `QuestCompletedMessageEvent` |
| 1122 | `SeasonalQuestsMessageEvent` |
| 1878 | `QuestDailyMessageEvent` |
| 2525 | `CommunityGoalProgressMessageEvent` |
| 2737 | `ConcurrentUsersGoalProgressMessageEvent` |
| 3005 | `CommunityGoalHallOfFameMessageEvent` |
| 3027 | `QuestCancelledMessageEvent` |
| 3319 | `CommunityGoalEarnedPrizesMessageEvent` |
| 3625 | `QuestsMessageEvent` |
| 3945 | `EpicPopupMessageEvent` |

### recycler

| ID | Class |
|----|-------|
| 468 | `RecyclerFinishedEvent` |
| 3164 | `RecyclerPrizesEvent` |
| 3433 | `RecyclerStatusEvent` |

### room/action

| ID | Class |
|----|-------|
| 1167 | `AvatarEffectMessageEvent` |
| 1474 | `CarryObjectMessageEvent` |
| 1631 | `ExpressionMessageEvent` |
| 1774 | `UseObjectMessageEvent` |
| 1797 | `SleepMessageEvent` |
| 2233 | `DanceMessageEvent` |

### room/bots

| ID | Class |
|----|-------|
| 69 | `BotSkillListUpdateEvent` |
| 296 | `BotForceOpenContextMenuEvent` |
| 639 | `BotErrorEvent` |
| 1618 | `BotCommandConfigurationEvent` |

### room/camera

| ID | Class |
|----|-------|
| 463 | `CameraSnapshotMessageEvent` |

### room/chat

| ID | Class |
|----|-------|
| 566 | `FloodControlMessageEvent` |
| 826 | `RemainingMutePeriodEvent` |
| 1036 | `ShoutMessageEvent` |
| 1191 | `RoomChatSettingsMessageEvent` |
| 1446 | `ChatMessageEvent` |
| 1717 | `UserTypingMessageEvent` |
| 2704 | `WhisperMessageEvent` |
| 2937 | `RoomFilterSettingsMessageEvent` |

### room/engine

| ID | Class |
|----|-------|
| 374 | `UsersEvent` |
| 558 | `HeightMapUpdateMessageEvent` |
| 749 | `RoomEntryInfoMessageEvent` |
| 1301 | `FloorHeightMapEvent` |
| 1369 | `ItemsEvent` |
| 1453 | `ObjectsDataUpdateMessageEvent` |
| 1534 | `ObjectAddMessageEvent` |
| 1640 | `UserUpdateEvent` |
| 1723 | `FurnitureAliasesMessageEvent` |
| 1778 | `ObjectsMessageEvent` |
| 2009 | `ItemUpdateMessageEvent` |
| 2187 | `ItemAddMessageEvent` |
| 2202 | `ItemDataUpdateMessageEvent` |
| 2454 | `RoomPropertyMessageEvent` |
| 2547 | `ObjectDataUpdateMessageEvent` |
| 2661 | `UserRemoveMessageEvent` |
| 2703 | `ObjectRemoveMessageEvent` |
| 2753 | `HeightMapEvent` |
| 3207 | `SlideObjectBundleMessageEvent` |
| 3208 | `ItemRemoveMessageEvent` |
| 3403 | `FavoriteMembershipUpdateMessageEvent` |
| 3547 | `RoomVisualizationSettingsEvent` |
| 3776 | `ObjectUpdateMessageEvent` |
| 3920 | `UserChangeMessageEvent` |

### room/furniture

| ID | Class |
|----|-------|
| 35 | `FurniRentOrBuyoutOfferMessageEvent` |
| 56 | `PresentOpenedMessageEvent` |
| 546 | `OpenPetPackageResultMessageEvent` |
| 909 | `CustomUserNotificationMessageEvent` |
| 1112 | `YoutubeDisplayPlaylistsEvent` |
| 1411 | `YoutubeDisplayVideoMessageEvent` |
| 1554 | `YoutubeControlVideoMessageEvent` |
| 1634 | `RoomMessageNotificationMessageEvent` |
| 1868 | `RentableSpaceRentFailedMessageEvent` |
| 2046 | `RentableSpaceRentOkMessageEvent` |
| 2366 | `RequestSpamWallPostItMessageEvent` |
| 2376 | `OneWayDoorStatusMessageEvent` |
| 2380 | `OpenPetPackageRequestedMessageEvent` |
| 2707 | `WelcomeGiftStatusEvent` |
| 2710 | `RoomDimmerPresetsEvent` |
| 3293 | `GuildFurniContextMenuInfoMessageEvent` |
| 3431 | `DiceValueMessageEvent` |
| 3559 | `RentableSpaceStatusMessageEvent` |

### room/layout

| ID | Class |
|----|-------|
| 1664 | `RoomEntryTileMessageEvent` |
| 3990 | `RoomOccupiedTilesMessageEvent` |

### room/permissions

| ID | Class |
|----|-------|
| 339 | `YouAreOwnerMessageEvent` |
| 780 | `YouAreControllerMessageEvent` |
| 2392 | `YouAreNotControllerMessageEvent` |

### room/pets

| ID | Class |
|----|-------|
| 1130 | `PetRespectFailedEvent` |
| 1164 | `PetTrainingPanelEvent` |
| 1553 | `PetBreedingResultEvent` |
| 1907 | `PetStatusUpdateEvent` |
| 1924 | `PetFigureUpdateEvent` |
| 2156 | `PetExperienceEvent` |
| 2824 | `PetLevelUpdateEvent` |
| 2901 | `PetInfoMessageEvent` |
| 2913 | `PetPlacingErrorEvent` |

### room/session

| ID | Class |
|----|-------|
| 122 | `CloseConnectionMessageEvent` |
| 160 | `RoomForwardMessageEvent` |
| 448 | `YouArePlayingGameMessageEvent` |
| 758 | `OpenConnectionMessageEvent` |
| 899 | `CantConnectMessageEvent` |
| 1033 | `YouAreSpectatorMessageEvent` |
| 2031 | `RoomReadyMessageEvent` |
| 2208 | `RoomQueueStatusMessageEvent` |
| 2324 | `GamePlayerValueMessageEvent` |
| 3783 | `FlatAccessibleMessageEvent` |

### roomsettings

| ID | Class |
|----|-------|
| 84 | `NoSuchFlatEvent` |
| 948 | `RoomSettingsSavedEvent` |
| 1284 | `FlatControllersEvent` |
| 1327 | `FlatControllerRemovedEvent` |
| 1498 | `RoomSettingsDataEvent` |
| 1555 | `RoomSettingsSaveErrorEvent` |
| 1869 | `BannedUsersFromRoomEvent` |
| 2088 | `FlatControllerAddedEvent` |
| 2533 | `MuteAllInRoomEvent` |
| 2897 | `RoomSettingsErrorEvent` |
| 3429 | `UserUnbannedFromRoomEvent` |
| 3896 | `ShowEnforceRoomCategoryDialogEvent` |

### snowwar:_Str_336

| ID | Class |
|----|-------|
| 5017 | `SnowStormOnStageStartEvent` |
| 5018 | `SnowStormIntializeGameArenaViewEvent` |
| 5019 | `SnowStormRejoinPreviousRoomEvent` |
| 5020 | `_SafeStr_3669` |
| 5021 | `SnowStormLevelDataEvent` |
| 5022 | `SnowStormOnGameEndingEvent` |
| 5023 | `SnowStormUserChatMessageEvent` |
| 5024 | `SnowStormOnStageRunningEvent` |
| 5025 | `SnowStormOnStageEndingEvent` |
| 5026 | `SnowStormIntializedPlayersEvent` |
| 5027 | `SnowStormOnPlayerExitedArenaEvent` |
| 5028 | `SnowStormGenericErrorEvent2` |
| 5029 | `SnowStormUserRematchedEvent` |

### snowwar:_Str_343

| ID | Class |
|----|-------|
| 5015 | `SnowStormGameStatusEvent` |
| 5016 | `SnowStormFullGameStatusEvent` |

### snowwar:_Str_448

| ID | Class |
|----|-------|
| 5000 | `SnowStormGameStartedEvent` |
| 5001 | `SnowStormQuePositionEvent` |
| 5002 | `SnowStormStartBlockTickerEvent` |
| 5003 | `StartLobbyCounterEvent` |
| 5004 | `SnowStormUnusedAlertGenericEvent` |
| 5005 | `SnowStormLongDataEvent` |
| 5006 | `SnowStormGameEndedEvent` |
| 5007 | `SnowStormGenericErrorEvent` |
| 5008 | `SnowStormQuePlayerAddedEvent` |
| 5009 | `SnowStormPlayAgainEvent` |
| 5010 | `SnowStormGamesLeftEvent` |
| 5011 | `SnowStormQuePlayerRemovedEvent` |
| 5012 | `SnowStormGamesInformationEvent` |
| 5013 | `SnowStormLongData2Event` |
| 5014 | `_SafeStr_3929` |

### sound

| ID | Class |
|----|-------|
| 34 | `JukeboxSongDisksMessageEvent` |
| 105 | `JukeboxPlayListFullMessageEvent` |
| 469 | `NowPlayingMessageEvent` |
| 1140 | `PlayListSongAddedMessageEvent` |
| 1381 | `OfficialSongIdMessageEvent` |
| 1748 | `PlayListMessageEvent` |
| 2602 | `UserSongDisksInventoryMessageEvent` |
| 3365 | `TraxSongInfoMessageEvent` |

### talent

| ID | Class |
|----|-------|
| 638 | `TalentLevelUpEvent` |
| 1203 | `TalentTrackLevelMessageEvent` |
| 3406 | `TalentTrackMessageEvent` |

### tracking

| ID | Class |
|----|-------|
| 10 | `LatencyPingResponseMessageEvent` |

### ui:widget/infobuspolls

| ID | Class |
|----|-------|
| 5200 | `StartRoomPollEvent` |
| 5201 | `RoomPollResultEvent` |

### userclassification

| ID | Class |
|----|-------|
| 966 | `UserClassificationMessageEvent` |

### userdefinedroomevents

| ID | Class |
|----|-------|
| 156 | `WiredValidationErrorEvent` |
| 178 | `WiredRewardResultMessageEvent` |
| 383 | `WiredTriggerDataEvent` |
| 1108 | `WiredConditionDataEvent` |
| 1155 | `WiredSavedEvent` |
| 1434 | `WiredEffectDataEvent` |
| 1830 | `OpenEvent` |

### users

| ID | Class |
|----|-------|
| 126 | `IgnoredUsersMessageEvent` |
| 207 | `IgnoreResultMessageEvent` |
| 265 | `GuildMembershipUpdatedMessageEvent` |
| 354 | `HandItemReceivedMessageEvent` |
| 420 | `GuildMembershipsMessageEvent` |
| 612 | `EmailStatusResultEvent` |
| 762 | `HabboGroupJoinFailedMessageEvent` |
| 818 | `GuildMemberMgmtFailedMessageEvent` |
| 876 | `ExtendedProfileChangedMessageEvent` |
| 954 | `ScrSendUserInfoEvent` |
| 1087 | `UserBadgesEvent` |
| 1180 | `GroupMembershipRequestedMessageEvent` |
| 1200 | `GuildMembersEvent` |
| 1243 | `AccountSafetyLockStatusChangeMessageEvent` |
| 1255 | `UserTagsMessageEvent` |
| 1459 | `GroupDetailsChangedMessageEvent` |
| 1503 | `ApproveNameMessageEvent` |
| 1702 | `HabboGroupDetailsMessageEvent` |
| 1815 | `ChangeEmailResultEvent` |
| 1876 | `GuildMemberFurniCountInHQMessageEvent` |
| 2016 | `RelationshipStatusInfoEvent` |
| 2023 | `InClientLinkMessageEvent` |
| 2159 | `GuildCreationInfoMessageEvent` |
| 2182 | `UserNameChangedMessageEvent` |
| 2238 | `GuildEditorDataMessageEvent` |
| 2293 | `WelcomeGiftChangeEmailResultEvent` |
| 2402 | `HabboGroupBadgesMessageEvent` |
| 2445 | `GuildMembershipRejectedMessageEvent` |
| 2788 | `PetRespectNotificationEvent` |
| 2808 | `GuildCreatedMessageEvent` |
| 2815 | `RoomUserRespect` |
| 3129 | `HabboGroupDeactivatedMessageEvent` |
| 3277 | `ScrSendKickbackInfoMessageEvent` |
| 3441 | `PetSupplementedNotificationEvent` |
| 3475 | `CreditBalanceEvent` |
| 3898 | `ExtendedProfileMessageEvent` |
| 3965 | `GuildEditInfoMessageEvent` |
| 3988 | `GuildEditFailedMessageEvent` |

## Outgoing Packets

### advertisement

| ID | Class |
|----|-------|
| 1109 | `InterstitialShownMessageComposer` |
| 2519 | `GetInterstitialMessageComposer` |

### avatar

| ID | Class |
|----|-------|
| 800 | `SaveWardrobeOutfitMessageComposer` |
| 2742 | `GetWardrobeMessageComposer` |
| 2977 | `ChangeUserNameMessageComposer` |
| 3950 | `CheckUserNameMessageComposer` |

### camera

| ID | Class |
|----|-------|
| 796 | `RequestCameraConfigurationComposer` |
| 1982 | `RenderRoomThumbnailMessageComposer` |
| 2068 | `PublishPhotoMessageComposer` |
| 2408 | `PurchasePhotoMessageComposer` |
| 3226 | `RenderRoomMessageComposer` |
| 3959 | `PhotoCompetitionMessageComposer` |

### campaign

| ID | Class |
|----|-------|
| 2257 | `OpenCampaignCalendarDoorAsStaffComposer` |
| 3889 | `OpenCampaignCalendarDoorComposer` |

### catalog

| ID | Class |
|----|-------|
| 223 | `GetBundleDiscountRulesetComposer` |
| 339 | `RedeemVoucherMessageComposer` |
| 410 | `GetLimitedOfferAppearingNextComposer` |
| 412 | `GetCatalogPageComposer` |
| 418 | `GetGiftWrappingConfigurationComposer` |
| 462 | `BuildersClubPlaceWallItemMessageComposer` |
| 487 | `GetClubGiftInfo` |
| 596 | `GetTargetedOfferComposer` |
| 603 | `GetHabboBasicMembershipExtendOfferComposer` |
| 742 | `GetCatalogPageExpirationComposer` |
| 777 | `PurchaseRoomAdMessageComposer` |
| 801 | `GetDirectClubBuyAvailableComposer` |
| 957 | `GetBonusRareInfoMessageComposer` |
| 1051 | `BuildersClubPlaceRoomItemMessageComposer` |
| 1075 | `GetRoomAdPurchaseInfoComposer` |
| 1195 | `GetCatalogIndexComposer` |
| 1347 | `GetIsOfferGiftableComposer` |
| 1411 | `PurchaseFromCatalogAsGiftComposer` |
| 1756 | `GetSellablePetPalettesComposer` |
| 1826 | `PurchaseTargetedOfferComposer` |
| 2041 | `SetTargetedOfferStateComposer` |
| 2150 | `MarkCatalogNewAdditionsPageOpenedComposer` |
| 2276 | `SelectClubGiftComposer` |
| 2283 | `RoomAdPurchaseInitiatedComposer` |
| 2462 | `GetHabboClubExtendOfferMessageComposer` |
| 2487 | `GetNextTargetedOfferComposer` |
| 2529 | `BuildersClubQueryFurniCountMessageComposer` |
| 2594 | `GetProductOfferComposer` |
| 2735 | `PurchaseBasicMembershipExtensionComposer` |
| 3135 | `GetCatalogPageWithEarliestExpiryComposer` |
| 3257 | `GetSeasonalCalendarDailyOfferComposer` |
| 3285 | `GetClubOffersMessageComposer` |
| 3407 | `PurchaseVipMembershipExtensionComposer` |
| 3483 | `ShopTargetedOfferViewedComposer` |
| 3492 | `PurchaseFromCatalogComposer` |

### competition

| ID | Class |
|----|-------|
| 143 | `VoteForRoomMessageComposer` |
| 172 | `ForwardToACompetitionRoomMessageComposer` |
| 271 | `GetSecondsUntilMessageComposer` |
| 865 | `ForwardToRandomCompetitionRoomMessageComposer` |
| 1334 | `RoomCompetitionInitMessageComposer` |
| 1450 | `ForwardToASubmittableRoomMessageComposer` |
| 2077 | `GetIsUserPartOfCompetitionMessageComposer` |
| 2595 | `SubmitRoomToCompetitionMessageComposer` |
| 2912 | `GetCurrentTimingCodeMessageComposer` |

### crafting

| ID | Class |
|----|-------|
| 633 | `GetCraftableProductsComposer` |
| 1173 | `GetCraftingRecipeComposer` |
| 1251 | `CraftSecretComposer` |
| 3086 | `GetCraftingRecipesAvailableComposer` |
| 3591 | `CraftComposer` |

### friendfurni

| ID | Class |
|----|-------|
| 3775 | `FriendFurniConfirmLockMessageComposer` |

### friendlist

| ID | Class |
|----|-------|
| 137 | `AcceptFriendMessageComposer` |
| 516 | `FindNewFriendsMessageComposer` |
| 1210 | `HabboSearchMessageComposer` |
| 1276 | `SendRoomInviteMessageComposer` |
| 1419 | `FriendListUpdateMessageComposer` |
| 1689 | `RemoveFriendMessageComposer` |
| 2448 | `GetFriendRequestsMessageComposer` |
| 2781 | `MessengerInitMessageComposer` |
| 2890 | `DeclineFriendMessageComposer` |
| 2970 | `FollowFriendMessageComposer` |
| 3157 | `RequestFriendMessageComposer` |
| 3567 | `SendMsgMessageComposer` |
| 3768 | `SetRelationshipStatusMessageComposer` |
| 3997 | `VisitUserMessageComposer` |

### game/arena

| ID | Class |
|----|-------|
| 1445 | `Game2ExitGameMessageComposer` |
| 2415 | `Game2LoadStageReadyMessageComposer` |
| 2502 | `Game2GameChatMessageComposer` |
| 3196 | `Game2PlayAgainMessageComposer` |

### game/directory

| ID | Class |
|----|-------|
| 11 | `Game2GetAccountGameStatusMessageComposer` |
| 3259 | `Game2CheckGameDirectoryStatusMessageComposer` |

### game/ingame

| ID | Class |
|----|-------|
| 1598 | `Game2RequestFullStatusUpdateMessageComposer` |

### game/lobby

| ID | Class |
|----|-------|
| 359 | `GetResolutionAchievementsMessageComposer` |
| 389 | `GetUserGameAchievementsMessageComposer` |
| 741 | `GetGameListMessageComposer` |
| 1458 | `JoinQueueMessageComposer` |
| 2384 | `LeaveQueueMessageComposer` |
| 2399 | `GetGameAchievementsMessageComposer` |
| 3144 | `ResetResolutionAchievementMessageComposer` |
| 3171 | `GetGameStatusMessageComposer` |
| 3207 | `GameUnloadedMessageComposer` |
| 3802 | `AcceptGameInviteMessageComposer` |

### game/score

| ID | Class |
|----|-------|
| 654 | `_Str_11321` |
| 1054 | `GetWeeklyGameRewardWinnersComposer` |
| 1081 | `_Str_11951` |
| 1232 | `Game2GetWeeklyFriendsLeaderboardComposer` |
| 1859 | `_Str_16422` |
| 2565 | `Game2GetWeeklyLeaderboardComposer` |
| 2914 | `GetWeeklyGameRewardComposer` |
| 3362 | `_Str_18174` |

### gifts

| ID | Class |
|----|-------|
| 790 | `TryPhoneNumberMessageComposer` |
| 1379 | `SetPhoneNumberVerificationStatusMessageComposer` |
| 2436 | `GetGiftMessageComposer` |
| 2721 | `VerifyCodeMessageComposer` |
| 2741 | `ResetPhoneNumberStateMessageComposer` |

### groupforums

| ID | Class |
|----|-------|
| 232 | `GetMessagesMessageComposer` |
| 286 | `ModerateMessageMessageComposer` |
| 436 | `GetThreadsMessageComposer` |
| 873 | `GetForumsListMessageComposer` |
| 1397 | `ModerateThreadMessageComposer` |
| 1855 | `UpdateForumReadMarkerMessageComposer` |
| 2214 | `UpdateForumSettingsMessageComposer` |
| 2908 | `GetUnreadForumsCountMessageComposer` |
| 3045 | `UpdateThreadMessageComposer` |
| 3149 | `GetForumStatsMessageComposer` |
| 3529 | `PostMessageMessageComposer` |
| 3900 | `GetThreadMessageComposer` |

### handshake

| ID | Class |
|----|-------|
| 357 | `InfoRetrieveMessageComposer` |
| 773 | `CompleteDiffieHandshakeMessageComposer` |
| 1053 | `VersionCheckMessageComposer` |
| 2419 | `SSOTicketMessageComposer` |
| 2445 | `DisconnectMessageComposer` |
| 2490 | `UniqueIDMessageComposer` |
| 2596 | `PongMessageComposer` |
| 3110 | `InitDiffieHandshakeMessageComposer` |
| 4000 | `ClientHelloMessageComposer` |

### help

| ID | Class |
|----|-------|
| 234 | `GuideSessionInviteRequesterMessageComposer` |
| 291 | `GuideSessionRequesterCancelsMessageComposer` |
| 477 | `GuideSessionFeedbackMessageComposer` |
| 519 | `GuideSessionIsTypingMessageComposer` |
| 534 | `CallForHelpFromForumThreadMessageComposer` |
| 887 | `GuideSessionResolvedMessageComposer` |
| 1052 | `GuideSessionGetRequesterRoomMessageComposer` |
| 1224 | `_Str_15943` |
| 1296 | `GetQuizQuestionsComposer` |
| 1412 | `CallForHelpFromForumMessageMessageComposer` |
| 1424 | `GuideSessionGuideDecidesMessageComposer` |
| 1691 | `CallForHelpMessageComposer` |
| 1849 | `GetFaqTextMessageComposer` |
| 1922 | `GuideSessionOnDutyUpdateMessageComposer` |
| 2031 | `SearchFaqsMessageComposer` |
| 2492 | `CallForHelpFromPhotoMessageComposer` |
| 2501 | `ChatReviewGuideDetachedMessageComposer` |
| 2746 | `GetCfhStatusMessageComposer` |
| 2755 | `CallForHelpFromSelfieMessageComposer` |
| 2950 | `CallForHelpFromIMMessageComposer` |
| 3060 | `ChatReviewSessionCreateMessageComposer` |
| 3267 | `GetPendingCallsForHelpMessageComposer` |
| 3338 | `GuideSessionCreateMessageComposer` |
| 3365 | `ChatReviewGuideDecidesOnOfferMessageComposer` |
| 3445 | `GetFaqCategoryMessageComposer` |
| 3605 | `DeletePendingCallsForHelpMessageComposer` |
| 3632 | `_Str_16470` |
| 3720 | `PostQuizAnswersComposer` |
| 3786 | `GetGuideReportingStatusMessageComposer` |
| 3899 | `GuideSessionMessageMessageComposer` |
| 3961 | `ChatReviewGuideVoteMessageComposer` |
| 3969 | `GuideSessionReportMessageComposer` |

### inventory/achievements

| ID | Class |
|----|-------|
| 219 | `GetAchievementsComposer` |

### inventory/avatareffect

| ID | Class |
|----|-------|
| 1752 | `AvatarEffectSelectedComposer` |
| 2959 | `AvatarEffectActivatedComposer` |

### inventory/badges

| ID | Class |
|----|-------|
| 644 | `SetActivatedBadgesComposer` |
| 1364 | `GetIsBadgeRequestFulfilledComposer` |
| 1371 | `GetBadgePointLimitsComposer` |
| 2769 | `GetBadgesComposer` |
| 3077 | `RequestABadgeComposer` |

### inventory/bots

| ID | Class |
|----|-------|
| 3848 | `GetBotInventoryComposer` |

### inventory/furni

| ID | Class |
|----|-------|
| 711 | `RequestRoomPropertySet` |
| 3150 | `RequestFurniInventoryComposer` |
| 3500 | `RequestFurniInventoryWhenNotInRoomComposer` |

### inventory/pets

| ID | Class |
|----|-------|
| 2713 | `CancelPetBreedingComposer` |
| 3095 | `GetPetInventoryComposer` |
| 3382 | `ConfirmPetBreedingComposer` |

### inventory/purse

| ID | Class |
|----|-------|
| 273 | `GetCreditsInfoComposer` |

### inventory/trading

| ID | Class |
|----|-------|
| 1263 | `AddItemsToTradeComposer` |
| 1444 | `UnacceptTradingComposer` |
| 1481 | `OpenTradingComposer` |
| 2341 | `ConfirmDeclineTradingComposer` |
| 2551 | `CloseTradingComposer` |
| 2760 | `ConfirmAcceptTradingComposer` |
| 3107 | `AddItemToTradeComposer` |
| 3845 | `RemoveItemFromTradeComposer` |
| 3863 | `AcceptTradingComposer` |

### landingview

| ID | Class |
|----|-------|
| 1827 | `GetPromoArticlesComposer` |

### landingview/votes

| ID | Class |
|----|-------|
| 3536 | `CommunityGoalVoteMessageComposer` |

### marketplace

| ID | Class |
|----|-------|
| 434 | `CancelMarketplaceOfferMessageComposer` |
| 848 | `GetMarketplaceCanMakeOfferComposer` |
| 1603 | `BuyMarketplaceOfferMessageComposer` |
| 1866 | `BuyMarketplaceTokensMessageComposer` |
| 2105 | `GetMarketplaceOwnOffersMessageComposer` |
| 2407 | `GetMarketplaceOffersMessageComposer` |
| 2597 | `GetMarketplaceConfigurationMessageComposer` |
| 2650 | `RedeemMarketplaceOfferCreditsMessageComposer` |
| 3288 | `GetMarketplaceItemStatsComposer` |
| 3447 | `MakeOfferMessageComposer` |

### moderator

| ID | Class |
|----|-------|
| 15 | `PickIssuesMessageComposer` |
| 31 | `ModToolPreferencesComposer` |
| 211 | `GetCfhChatlogMessageComposer` |
| 229 | `ModAlertMessageComposer` |
| 707 | `GetModeratorRoomInfoMessageComposer` |
| 1391 | `GetUserChatlogMessageComposer` |
| 1392 | `ModToolSanctionComposer` |
| 1572 | `ReleaseIssuesMessageComposer` |
| 1681 | `DefaultSanctionMessageComposer` |
| 1840 | `ModMessageMessageComposer` |
| 1945 | `ModMuteMessageComposer` |
| 2067 | `CloseIssuesMessageComposer` |
| 2582 | `ModKickMessageComposer` |
| 2587 | `GetRoomChatlogMessageComposer` |
| 2717 | `CloseIssueDefaultActionMessageComposer` |
| 2766 | `ModBanMessageComposer` |
| 3260 | `ModerateRoomMessageComposer` |
| 3295 | `GetModeratorUserInfoMessageComposer` |
| 3526 | `GetRoomVisitsMessageComposer` |
| 3742 | `ModTradingLockMessageComposer` |
| 3842 | `ModeratorActionMessageComposer` |

### mysterybox

| ID | Class |
|----|-------|
| 2012 | `MysteryBoxWaitingCanceledMessageComposer` |

### navigator

| ID | Class |
|----|-------|
| 10 | `ForwardToARandomPromotedRoomMessageComposer` |
| 39 | `MyGuildBasesSearchMessageComposer` |
| 272 | `MyRoomRightsSearchMessageComposer` |
| 309 | `DeleteFavouriteRoomMessageComposer` |
| 314 | `ConvertGlobalRoomIdMessageComposer` |
| 433 | `CompetitionRoomsSearchMessageComposer` |
| 826 | `GetPopularRoomTagsMessageComposer` |
| 1002 | `MyFrequentRoomHistorySearchMessageComposer` |
| 1229 | `GetOfficialRoomsMessageComposer` |
| 1703 | `ForwardToSomeRoomMessageComposer` |
| 1740 | `UpdateHomeRoomMessageComposer` |
| 1782 | `GetUserEventCatsMessageComposer` |
| 1786 | `RoomsWhereMyFriendsAreSearchMessageComposer` |
| 1918 | `ToggleStaffPickMessageComposer` |
| 2128 | `CanCreateRoomMessageComposer` |
| 2230 | `GetGuestRoomMessageComposer` |
| 2264 | `MyRoomHistorySearchMessageComposer` |
| 2266 | `MyFriendsRoomsSearchMessageComposer` |
| 2277 | `MyRoomsSearchMessageComposer` |
| 2412 | `RoomAdEventTabAdClickedComposer` |
| 2468 | `UpdateRoomThumbnailMessageComposer` |
| 2537 | `MyRecommendedRoomsMessageComposer` |
| 2578 | `MyFavouriteRoomsSearchMessageComposer` |
| 2668 | `RoomAdEventTabViewedComposer` |
| 2725 | `CancelEventMessageComposer` |
| 2752 | `CreateFlatMessageComposer` |
| 2758 | `PopularRoomsSearchMessageComposer` |
| 2809 | `RoomAdSearchMessageComposer` |
| 2930 | `GuildBaseSearchMessageComposer` |
| 2939 | `RoomsWithHighestScoreSearchMessageComposer` |
| 3027 | `GetUserFlatCatsMessageComposer` |
| 3182 | `RemoveOwnRoomRightsRoomMessageComposer` |
| 3305 | `SetRoomSessionTagsMessageComposer` |
| 3582 | `RateFlatMessageComposer` |
| 3782 | `GetCategoriesWithUserCountMessageComposer` |
| 3817 | `AddFavouriteRoomMessageComposer` |
| 3943 | `RoomTextSearchMessageComposer` |
| 3991 | `EditEventMessageComposer` |

### newnavigator

| ID | Class |
|----|-------|
| 249 | `NewNavigatorSearchComposer` |
| 637 | `NavigatorRemoveCollapsedCategoryMessageComposer` |
| 1202 | `NavigatorSetSearchCodeViewModeMessageComposer` |
| 1834 | `NavigatorAddCollapsedCategoryMessageComposer` |
| 1954 | `NavigatorDeleteSavedSearchComposer` |
| 2110 | `NewNavigatorInitComposer` |
| 2226 | `NavigatorAddSavedSearchComposer` |

### notifications

| ID | Class |
|----|-------|
| 2343 | `ResetUnseenItemsComposer` |
| 3493 | `ResetUnseenItemIdsComposer` |

### nux

| ID | Class |
|----|-------|
| 1299 | `NewUserExperienceScriptProceedComposer` |
| 1822 | `NewUserExperienceGetGiftsMessageComposer` |

### poll

| ID | Class |
|----|-------|
| 109 | `PollStartComposer` |
| 1773 | `PollRejectComposer` |
| 3505 | `PollAnswerComposer` |

### preferences

| ID | Class |
|----|-------|
| 1030 | `SetChatStylePreferenceComposer` |
| 1086 | `SetIgnoreRoomInvitesMessageComposer` |
| 1262 | `SetChatPreferencesMessageComposer` |
| 1367 | `SetSoundSettingsComposer` |
| 1461 | `SetRoomCameraPreferencesMessageComposer` |
| 3159 | `SetNewNavigatorWindowPreferencesMessageComposer` |

### quest

| ID | Class |
|----|-------|
| 90 | `RedeemCommunityGoalPrizeMessageComposer` |
| 793 | `ActivateQuestMessageComposer` |
| 1145 | `GetCommunityGoalProgressMessageComposer` |
| 1148 | `FriendRequestQuestCompleteMessageComposer` |
| 1190 | `GetSeasonalQuestsOnlyMessageComposer` |
| 1343 | `GetConcurrentUsersGoalProgressMessageComposer` |
| 1697 | `StartCampaignMessageComposer` |
| 2167 | `GetCommunityGoalHallOfFameMessageComposer` |
| 2397 | `RejectQuestMessageComposer` |
| 2486 | `GetDailyQuestMessageComposer` |
| 2688 | `GetCommunityGoalEarnedPrizesMessageComposer` |
| 2750 | `OpenQuestTrackerMessageComposer` |
| 3133 | `CancelQuestMessageComposer` |
| 3333 | `GetQuestsMessageComposer` |
| 3604 | `AcceptQuestMessageComposer` |
| 3872 | `GetConcurrentUsersRewardMessageComposer` |

### recycler

| ID | Class |
|----|-------|
| 398 | `GetRecyclerPrizesMessageComposer` |
| 1342 | `GetRecyclerStatusMessageComposer` |
| 2771 | `RecycleItemsMessageComposer` |

### register

| ID | Class |
|----|-------|
| 2730 | `UpdateFigureDataMessageComposer` |

### room/action

| ID | Class |
|----|-------|
| 808 | `AssignRightsMessageComposer` |
| 992 | `UnbanUserFromRoomMessageComposer` |
| 1320 | `RoomUserKickMessageComposer` |
| 1477 | `BanUserWithDurationMessageComposer` |
| 1644 | `LetUserInMessageComposer` |
| 2064 | `RemoveRightsMessageComposer` |
| 2683 | `RemoveAllRightsMessageComposer` |
| 2996 | `AmbassadorAlertMessageComposer` |
| 3485 | `RoomUserMuteMessageComposer` |
| 3637 | `MuteAllInRoomComposer` |

### room/avatar

| ID | Class |
|----|-------|
| 1975 | `SignMessageComposer` |
| 2080 | `DanceMessageComposer` |
| 2228 | `ChangeMottoMessageComposer` |
| 2235 | `ChangePostureMessageComposer` |
| 2456 | `AvatarExpressionMessageComposer` |
| 2768 | `PassCarryItemToPetMessageComposer` |
| 2814 | `DropCarryItemMessageComposer` |
| 2941 | `PassCarryItemMessageComposer` |
| 3301 | `LookToMessageComposer` |
| 3374 | `CustomizeAvatarWithFurniMessageComposer` |

### room/bots

| ID | Class |
|----|-------|
| 1986 | `GetBotCommandConfigurationDataComposer` |
| 2624 | `CommandBotComposer` |

### room/chat

| ID | Class |
|----|-------|
| 1314 | `ChatMessageComposer` |
| 1474 | `CancelTypingMessageComposer` |
| 1543 | `WhisperMessageComposer` |
| 1597 | `StartTypingMessageComposer` |
| 2085 | `ShoutMessageComposer` |

### room/engine

| ID | Class |
|----|-------|
| 99 | `UseFurnitureMessageComposer` |
| 168 | `MoveWallItemMessageComposer` |
| 186 | `RemoveSaddleFromPetMessageComposer` |
| 210 | `UseWallItemMessageComposer` |
| 248 | `MoveObjectMessageComposer` |
| 749 | `GiveSupplementToPetMessageComposer` |
| 924 | `SetClothingChangeDataMessageComposer` |
| 1036 | `MountPetMessageComposer` |
| 1258 | `PlaceObjectMessageComposer` |
| 1472 | `TogglePetRidingPermissionMessageComposer` |
| 1521 | `HarvestPetMessageComposer` |
| 1581 | `RemovePetFromFlatMessageComposer` |
| 1592 | `PlaceBotMessageComposer` |
| 2161 | `GetPetCommandsMessageComposer` |
| 2300 | `GetRoomEntryDataMessageComposer` |
| 2647 | `PlacePetMessageComposer` |
| 3320 | `MoveAvatarMessageComposer` |
| 3323 | `RemoveBotFromFlatMessageComposer` |
| 3336 | `RemoveItemMessageComposer` |
| 3379 | `TogglePetBreedingPermissionMessageComposer` |
| 3449 | `MovePetMessageComposer` |
| 3456 | `PickupObjectMessageComposer` |
| 3608 | `SetObjectDataMessageComposer` |
| 3666 | `SetItemDataMessageComposer` |
| 3835 | `CompostPlantMessageComposer` |
| 3898 | `GetFurnitureAliasesMessageComposer` |
| 3964 | `GetItemDataMessageComposer` |

### room/furniture

| ID | Class |
|----|-------|
| 336 | `GetYoutubeDisplayStatusMessageComposer` |
| 872 | `RentableSpaceStatusMessageComposer` |
| 1071 | `ExtendRentOrBuyoutFurniMessageComposer` |
| 1533 | `DiceOffMessageComposer` |
| 1648 | `RoomDimmerSavePresetMessageComposer` |
| 1667 | `RentableSpaceCancelRentMessageComposer` |
| 1990 | `ThrowDiceMessageComposer` |
| 2069 | `SetYoutubeDisplayPlaylistMessageComposer` |
| 2115 | `ExtendRentOrBuyoutStripItemMessageComposer` |
| 2144 | `SpinWheelOfFortuneMessageComposer` |
| 2209 | `SetMannequinFigureComposer` |
| 2248 | `PlacePostItMessageComposer` |
| 2296 | `RoomDimmerChangeStateMessageComposer` |
| 2518 | `GetRentOrBuyoutOfferMessageComposer` |
| 2638 | `OpenWelcomeGiftComposer` |
| 2651 | `GetGuildFurniContextMenuInfoMessageComposer` |
| 2765 | `EnterOneWayDoorMessageComposer` |
| 2813 | `RoomDimmerGetPresetsMessageComposer` |
| 2850 | `SetMannequinNameComposer` |
| 2880 | `SetRoomBackgroundColorDataComposer` |
| 2946 | `RentableSpaceRentMessageComposer` |
| 3005 | `ControlYoutubeDisplayPlaybackMessageComposer` |
| 3074 | `OpenMysteryTrophyMessageComposer` |
| 3115 | `CreditFurniRedeemMessageComposer` |
| 3283 | `AddSpamWallPostItMessageComposer` |
| 3558 | `PresentOpenMessageComposer` |
| 3617 | `SetRandomStateMessageComposer` |
| 3698 | `OpenPetPackageMessageComposer` |
| 3839 | `SetCustomStackingHeightComposer` |

### room/layout

| ID | Class |
|----|-------|
| 875 | `UpdateFloorPropertiesMessageComposer` |
| 1687 | `GetOccupiedTilesMessageComposer` |
| 3559 | `GetRoomEntryTileMessageComposer` |

### room/pets

| ID | Class |
|----|-------|
| 549 | `PetSelectedMessageComposer` |
| 1328 | `CustomizePetWithFurniComposer` |
| 1638 | `BreedPetsMessageComposer` |
| 2934 | `GetPetInfoMessageComposer` |
| 3202 | `RespectPetMessageComposer` |

### room/session

| ID | Class |
|----|-------|
| 105 | `QuitMessageComposer` |
| 685 | `GoToFlatMessageComposer` |
| 2312 | `OpenFlatConnectionMessageComposer` |
| 3093 | `ChangeQueueMessageComposer` |

### roomdirectory

| ID | Class |
|----|-------|
| 3736 | `RoomNetworkOpenConnectionMessageComposer` |

### roomsettings

| ID | Class |
|----|-------|
| 532 | `DeleteRoomMessageComposer` |
| 1265 | `UpdateRoomCategoryAndTradeSettingsComposer` |
| 1911 | `GetCustomRoomFilterMessageComposer` |
| 1969 | `SaveRoomSettingsMessageComposer` |
| 2267 | `GetBannedUsersFromRoomMessageComposer` |
| 3001 | `UpdateRoomFilterMessageComposer` |
| 3129 | `GetRoomSettingsMessageComposer` |
| 3385 | `GetFlatControllersMessageComposer` |

### snowwar:_Str_345

| ID | Class |
|----|-------|
| 6017 | `_SafeStr_1434` |
| 6018 | `_SafeStr_2571` |
| 6019 | `_SafeStr_2573` |
| 6020 | `_SafeStr_2576` |
| 6021 | `_SafeStr_2577` |

### snowwar:_Str_373

| ID | Class |
|----|-------|
| 6013 | `_SafeStr_2954` |
| 6014 | `_SafeStr_3643` |
| 6015 | `_SafeStr_3665` |
| 6016 | `_SafeStr_3918` |

### snowwar:_Str_400

| ID | Class |
|----|-------|
| 6008 | `_SafeStr_2507` |
| 6009 | `_SafeStr_2513` |
| 6010 | `_SafeStr_2519` |
| 6011 | `_SafeStr_3624` |
| 6012 | `_SafeStr_3813` |

### snowwar:_Str_477

| ID | Class |
|----|-------|
| 6000 | `_SafeStr_3633` |
| 6001 | `_SafeStr_3690` |
| 6002 | `_SafeStr_3694` |
| 6003 | `_SafeStr_3715` |
| 6004 | `_SafeStr_3776` |
| 6005 | `_SafeStr_3792` |
| 6006 | `_SafeStr_3836` |
| 6007 | `_SafeStr_3881` |

### snowwar:outgoing

| ID | Class |
|----|-------|
| 6022 | `_SafeStr_3806` |
| 6023 | `_SafeStr_3904` |
| 6024 | `_SafeStr_3908` |
| 6025 | `_SafeStr_3935` |
| 6026 | `_SafeStr_3969` |

### sound

| ID | Class |
|----|-------|
| 753 | `AddJukeboxDiskComposer` |
| 1325 | `GetNowPlayingMessageComposer` |
| 1435 | `GetJukeboxPlayListMessageComposer` |
| 2388 | `GetSoundSettingsComposer` |
| 3050 | `RemoveJukeboxDiskComposer` |
| 3082 | `GetSongInfoMessageComposer` |
| 3189 | `GetOfficialSongIdMessageComposer` |
| 3498 | `GetSoundMachinePlayListMessageComposer` |

### talent

| ID | Class |
|----|-------|
| 196 | `GetTalentTrackMessageComposer` |
| 2127 | `GetTalentTrackLevelMessageComposer` |
| 2455 | `GuideAdvertisementReadMessageComposer` |

### tracking

| ID | Class |
|----|-------|
| 96 | `LatencyPingReportMessageComposer` |
| 295 | `LatencyPingRequestMessageComposer` |
| 3230 | `PerformanceLogMessageComposer` |
| 3457 | `EventLogMessageComposer` |
| 3847 | `LagWarningReportMessageComposer` |

### ui:widget/infobuspolls

| ID | Class |
|----|-------|
| 6200 | `VotePollCounterMessageComposer` |

### userclassification

| ID | Class |
|----|-------|
| 1160 | `PeerUsersClassificationMessageComposer` |
| 2285 | `RoomUsersClassificationMessageComposer` |

### userdefinedroomevents

| ID | Class |
|----|-------|
| 1520 | `UpdateTriggerMessageComposer` |
| 2281 | `UpdateActionMessageComposer` |
| 3203 | `UpdateConditionMessageComposer` |
| 3373 | `ApplySnapshotMessageComposer` |

### users

| ID | Class |
|----|-------|
| 17 | `GetUserTagsMessageComposer` |
| 21 | `GetHabboGroupBadgesMessageComposer` |
| 66 | `WelcomeGiftChangeEmailComposer` |
| 230 | `CreateGuildMessageComposer` |
| 312 | `GetGuildMembersMessageComposer` |
| 367 | `GetGuildMembershipsMessageComposer` |
| 593 | `KickMemberMessageComposer` |
| 722 | `RemoveAdminRightsFromMemberMessageComposer` |
| 798 | `GetGuildCreationInfoMessageComposer` |
| 813 | `GetGuildEditorDataMessageComposer` |
| 869 | `ScrGetKickbackInfoMessageComposer` |
| 882 | `ApproveAllMembershipRequestsMessageComposer` |
| 998 | `JoinHabboGroupMessageComposer` |
| 1004 | `GetGuildEditInfoMessageComposer` |
| 1117 | `IgnoreUserMessageComposer` |
| 1118 | `WhiperGroupComposer` |
| 1134 | `DeactivateGuildMessageComposer` |
| 1523 | `GetMOTDMessageComposer` |
| 1764 | `UpdateGuildColorsMessageComposer` |
| 1820 | `DeselectFavouriteHabboGroupMessageComposer` |
| 1894 | `RejectMembershipRequestMessageComposer` |
| 1991 | `UpdateGuildBadgeMessageComposer` |
| 2061 | `UnignoreUserMessageComposer` |
| 2091 | `GetSelectedBadgesMessageComposer` |
| 2109 | `ApproveNameMessageComposer` |
| 2138 | `GetRelationshipStatusInfoMessageComposer` |
| 2249 | `GetExtendedProfileByNameMessageComposer` |
| 2557 | `GetEmailStatusComposer` |
| 2694 | `RespectUserMessageComposer` |
| 2864 | `UnblockGroupMemberMessageComposer` |
| 2894 | `AddAdminRightsToMemberMessageComposer` |
| 2991 | `GetHabboGroupDetailsMessageComposer` |
| 3137 | `UpdateGuildIdentityMessageComposer` |
| 3166 | `ScrGetUserInfoMessageComposer` |
| 3265 | `GetExtendedProfileMessageComposer` |
| 3314 | `IgnoreUserIdMessageComposer` |
| 3386 | `ApproveMembershipRequestMessageComposer` |
| 3435 | `UpdateGuildSettingsMessageComposer` |
| 3549 | `SelectFavouriteHabboGroupMessageComposer` |
| 3593 | `GetMemberGuildItemCountMessageComposer` |
| 3878 | `GetIgnoredUsersMessageComposer` |
| 3965 | `ChangeEmailComposer` |

