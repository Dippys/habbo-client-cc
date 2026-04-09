# Application Lifecycle

The Habbo client follows a carefully orchestrated bootstrap sequence from SWF load to fully interactive hotel view. This document details each phase of the application lifecycle.

## Lifecycle Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION LIFECYCLE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐                                                        │
│  │   SWF Loading    │  ─── Flash Player loads habbo.swf                      │
│  │  (0% - 60%)      │        │                                                │
│  └────────┬─────────┘        │                                                │
│           │                   ▼                                                │
│           │          ┌────────────────────┐                                   │
│           │          │    Habbo()          │  src/Habbo.as:74                 │
│           │          │   Constructor      │  - Initializes stage             │
│           │          └────────┬───────────┘  - Loads configuration           │
│           │                   │                                                  │
│           │                   ▼                                                  │
│           │          ┌────────────────────┐                                   │
│           │          │  onAddedToStage()   │  src/Habbo.as:218                │
│           │          │ + trackLoginStep() │  - CLIENT_INIT_START             │
│           │          └────────┬───────────┘                                   │
│           │                   │                                                  │
│           │                   ▼                                                  │
│           │          ┌────────────────────┐                                   │
│           │          │ createNewUserLobby │  src/Habbo.as:324                │
│           │          │  OrLoadingScreen() │  - Wraps createLoadingScreen:343 │
│           │          └────────┬───────────┘                                   │
│           │                   │                                                  │
│           │                   ▼                                                  │
│           │          ┌────────────────────┐                                   │
│           │          │finalizePreloading()│  src/Habbo.as:379-403            │
│           │          │+ trackLoginStep()  │  - SWF fully loaded              │
│           │          └────────┬───────────┘  - CLIENT_INIT_SWF_LOADED        │
│           │                   │                                                  │
│           │                   ▼                                                  │
│           │          ┌────────────────────┐                                   │
│           │          │   HabboMain()       │  src/HabboMain.as:35             │
│           │          │  Constructor        │  - Receives loading screen      │
│           │          │ (IHabboLoading)    │  - Registers event listeners    │
│           │          └────────┬───────────┘                                   │
│           │                   │                                                  │
│           ▼                   ▼                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                      CORE INITIALIZATION PHASE                        │    │
│  │                       (60% - 100% progress)                          │    │
│  │                                                                       │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │    │
│  │  │              prepareCore() - src/HabboMain.as:102             │  │    │
│  │  │                                                                  │  │    │
│  │  │  1. Create ICoreErrorLogger (HabboCoreErrorReporter)          │  │    │
│  │  │  2. Instantiate Core via Core.instantiate()                    │  │    │
│  │  │  3. Register 30+ components via _core.prepareComponent()      │  │    │
│  │  │  4. Read config document (asset libraries)                     │  │    │
│  │  │  5. Add initialization progress listeners                      │  │    │
│  │  │                                                                  │  │    │
│  │  └─────────────────────────────────────────────────────────────────┘  │    │
│  │                                    │                                      │    │
│  │                                    ▼                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │    │
│  │  │              File Loading Progress                              │  │    │
│  │  │                                                                  │  │    │
│  │  │  - onProgressEvent() - files loading, updates progress bar    │  │    │
│  │  │  - updateProgressBar() - formula:                              │  │    │
│  │  │      CORE_RATIO + ((completedSteps + loadedFiles) / totalSteps│  │    │
│  │  │                      * (1 - CORE_RATIO))                       │  │    │
│  │  │                                                                  │  │    │
│  │  └─────────────────────────────────────────────────────────────────┘  │    │
│  │                                    │                                      │    │
│  │                                    ▼                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │    │
│  │  │              onCompleteEvent() - src/HabboMain.as:181         │  │    │
│  │  │                   └─> initializeCore()                         │  │    │
│  │  │                                                                  │  │    │
│  │  │  - _core.initialize() - starts all registered components      │  │    │
│  │  │  - ExternalInterface callback for 'unloading'                 │  │    │
│  │  │                                                                  │  │    │
│  │  └─────────────────────────────────────────────────────────────────┘  │    │
│  │                                    │                                      │    │
│  │                                    ▼                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │    │
│  │  │              Initialization Complete Events                    │  │    │
│  │  │                                                                  │  │    │
│  │  │  onLocalizationComplete()  ──> CLIENT_INIT_LOCALIZATION_LOADED│  │    │
│  │  │  onConfigurationComplete() ──> CLIENT_INIT_CONFIG_LOADED       │  │    │
│  │  │  onRoomEngineReady()       ──> CLIENT_INIT_ROOM_READY          │  │    │
│  │  │  onCoreRunning()           ──> CLIENT_INIT_CORE_RUNNING         │  │    │
│  │  │                                                                  │  │    │
│  │  └─────────────────────────────────────────────────────────────────┘  │    │
│  │                                    │                                      │    │
│  │                                    ▼                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │    │
│  │  │              onExitFrame() - src/HabboMain.as:94              │  │    │
│  │  │                                                                  │  │    │
│  │  │  - Disposes HabboMain when roomEngineReady && coreRunning      │  │    │
│  │  │                                                                  │  │    │
│  │  └─────────────────────────────────────────────────────────────────┘  │    │
│  │                                                                       │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│           │                                                                   │
│           ▼                                                                   │
│  ┌──────────────────┐                                                        │
│  │   Hotel View     │  ─── Client fully initialized                        │
│  │   Ready State    │        - Can connect to server                       │
│  │                  │        - UI is responsive                             │
│  └──────────────────┘                                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Phase 1: SWF Loading (0% - 60%)

### Entry Point: Habbo Constructor
**File:** `src/Habbo.as:74`

The main application class is instantiated when the Flash SWF is loaded into the browser.

```actionscript
public function Habbo()
{
    // Initialize stage, load configuration
    // Called automatically by Flash Player
}
```

### Key Actions in Constructor Phase

| Step | Location | Action |
|------|----------|--------|
| 1 | `Habbo.as:218` | `onAddedToStage()` - stage initialization |
| 2 | `Habbo.as:223` | Track: `CLIENT_INIT_START` |
| 3 | `Habbo.as:324-341` | `createNewUserLobbyOrLoadingScreen()` - creates UI |
| 4 | `Habbo.as:379-403` | `finalizePreloading()` - SWF fully loaded |
| 5 | `Habbo.as:383` | Track: `CLIENT_INIT_SWF_LOADED` |
| 6 | `Habbo.as:390-402` | Instantiate `HabboMain` with loading screen |

### Loading Progress Formula

The loading bar uses `CORE_RATIO = 0.6` (60%):

```actionscript
// src/Habbo.as:360-377
k = (bytesLoaded / APPROXIMATE_SWF_SIZE) * CORE_RATIO
// Result: 0% to 60% during SWF loading
```

## Phase 2: Core Initialization (60% - 100%)

### Entry Point: HabboMain
**File:** `src/HabboMain.as:35`

The `HabboMain` class coordinates all component initialization.

```actionscript
public function HabboMain(k:IHabboLoadingScreen)
{
    this._loadingScreen = k;
    addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
    addEventListener(Event.EXIT_FRAME, this.onExitFrame);
}
```

### Core Instantiation
**Location:** `src/HabboMain.as:106-107`

```actionscript
var k:ICoreErrorLogger = ((Capabilities.playerType != "StandAlone") 
    ? new HabboCoreErrorReporter() 
    : null);
this._core = Core.instantiate(stage, Core.CORE_SETUP_FRAME_UPDATE_COMPLEX, k);
```

### Component Registration Order
**Location:** `src/HabboMain.as:108-156`

The following components are registered in order:

| Order | Component | Purpose |
|-------|-----------|---------|
| 1 | `HabboTrackingLib` | Analytics and error tracking |
| 2 | `CoreCommunicationFrameworkLib` | Socket communication framework |
| 3 | `HabboRoomObjectLogicLib` | Room object logic base |
| 4 | `HabboRoomObjectVisualizationLib` | Room object rendering |
| 5 | `RoomManagerLib` | Room management |
| 6 | `RoomSpriteRendererLib` | Sprite rendering |
| 7 | `HabboRoomSessionManagerLib` | Room session tracking |
| 8 | `HabboAvatarRenderLib` | Avatar rendering |
| 9 | `HabboSessionDataManagerLib` | User session data |
| 10 | `HabboConfigurationCom` | Client configuration |
| 11 | `HabboLocalizationCom` | String localization |
| 12 | `HabboWindowManagerCom` | UI window system |
| 13 | `HabboCommunicationCom` | Server connection |
| 14 | `HabboCommunicationDemoCom` | Demo mode |
| 15 | `HabboNavigatorCom` | Room browser |
| 16 | `HabboFriendListCom` | Friends UI |
| 17 | `HabboMessengerCom` | Chat/messaging |
| 18 | `HabboInventoryCom` | Inventory |
| 19 | `HabboToolbarCom` | Toolbar |
| 20 | `HabboCatalogCom` | Shop/catalog |
| 21 | `HabboRoomEngineCom` | Room engine |
| 22 | `HabboRoomUICom` | Room UI |
| 23 | `HabboAvatarEditorCom` | Avatar editor |
| 24 | `HabboNotificationsCom` | Notifications |
| 25 | `HabboHelpCom` | Help system |
| 26 | `HabboAdManagerCom` | Advertising |
| 27 | `HabboModerationCom` | Moderation tools |
| 28 | `HabboUserDefinedRoomEventsCom` | Wired events |
| 29 | `HabboSoundManagerFlash10Com` | Audio |
| 30 | `HabboQuestEngineCom` | Quests/achievements |
| 31 | `HabboFriendBarCom` | Friend bar |
| 32 | `HabboGroupsCom` | Guilds |
| 33 | `HabboGamesCom` | Games |
| 34 | `HabboFreeFlowChatCom` | Chat improvements |
| 35 | `HabboNewNavigatorCom` | New navigator |

### Asset Libraries Configuration
**Location:** `src/HabboMain.as:111-119`

```actionscript
var _local_2:XML = <config>
    <asset-libraries>
        <library url="hh_human_body.swf"/>
        <library url="hh_human_item.swf"/>
    </asset-libraries>
    <service-libraries/>
    <component-libraries/>
</config>;
```

### Progress Bar Updates
**Location:** `src/HabboMain.as:165-173`

```actionscript
k = (CORE_RATIO + (((this._completedInitSteps + this._loadedFiles) / this._totalSteps) * (1 - CORE_RATIO)))
// Fills from 60% to 100%
```

Variables:
- `_completedInitSteps`: Steps completed (localization, config, room, core)
- `_loadedFiles`: Files loaded by core
- `_totalSteps`: Pending + loaded files + 3

## Phase 3: Core Initialization Complete

### initializeCore()
**Location:** `src/HabboMain.as:188-205`

```actionscript
private function initializeCore():void
{
    Habbo.trackLoginStep("Initializing Core!");
    try
    {
        this._core.initialize();
        if (ExternalInterface.available)
        {
            ExternalInterface.addCallback("unloading", this.unloading);
        }
    }
    catch(error:Error)
    {
        // Error handling and crash reporting
    }
}
```

### Initialization Complete Events

| Event | Location | Tracking Step |
|-------|----------|---------------|
| `onLocalizationComplete()` | `HabboMain.as:230` | `CLIENT_INIT_LOCALIZATION_LOADED` |
| `onConfigurationComplete()` | `HabboMain.as:237` | `CLIENT_INIT_CONFIG_LOADED` |
| `onRoomEngineReady()` | `HabboMain.as:244` | `CLIENT_INIT_ROOM_READY` |
| `onCoreRunning()` | `HabboMain.as:265` | `CLIENT_INIT_CORE_RUNNING` |

### Cleanup
**Location:** `HabboMain.as:94-100`

```actionscript
private function onExitFrame(k:Event=null):void
{
    if (this.roomEngineReady && this.coreRunning)
    {
        this.dispose();
    }
}
```

## Login Step Tracking

### ClientEnum Tracking Values

| Constant | Value | Purpose |
|----------|-------|---------|
| `CLIENT_INIT_START` | `client.init.start` | Initial load started |
| `CLIENT_INIT_SWF_LOADED` | `client.init.swf.loaded` | SWF fully loaded |
| `CLIENT_INIT_LOCALIZATION_LOADED` | `client.init.localization.loaded` | Strings loaded |
| `CLIENT_INIT_CONFIG_LOADED` | `client.init.config.loaded` | Config loaded |
| `CLIENT_INIT_ROOM_READY` | `client.init.room.ready` | Room engine ready |
| `CLIENT_INIT_CORE_RUNNING` | `client.init.core.running` | Core running |
| `CLIENT_INIT_CORE_FAIL` | `client.init.core.fail` | Initialization failed |

### HabboLoginTrackingStep Values

| Constant | Value | When Tracked |
|----------|-------|--------------|
| `CLIENT_INIT_SOCKET_INIT` | `client.init.socket.init` | Socket connection start |
| `CLIENT_INIT_SOCKET_OK` | `client.init.socket.ok` | Socket connected |
| `CLIENT_INIT_HANDSHAKE_START` | `client.init.handshake.start` | Encryption handshake start |
| `CLIENT_INIT_HANDSHAKE_OK` | `client.init.handshake.ok` | Handshake complete |
| `CLIENT_INIT_AUTH_OK` | `client.init.auth.ok` | Authentication successful |
| `CLIENT_INIT_ROOM_ENTER` | `client.init.room.enter` | Entered room |
| `CLIENT_INIT_HOTELVIEW_START` | `client.init.hotelview.start` | Hotel view shown |
| `CLIENT_INIT_HOTELVIEW_OK` | `client.init.hotelview.ok` | Hotel view ready |

## Key Files Reference

| File | Lines | Purpose |
|------|-------|---------|
| `src/Habbo.as` | 74-403 | Main application, SWF loading |
| `src/HabboMain.as` | 1-286 | Component initialization |
| `src/HabboLoadingScreen.as` | - | Progress bar UI |
| `src/ClientEnum.as` | 1-16 | Tracking constants |
| `src/HabboLoginTrackingStep.as` | 1-16 | Connection tracking |

## Next Steps

- [Component Model](Architecture/Component-Model) - Sulake framework details
- [Directory Structure](Architecture/Directory-Structure) - Package organization
- [Networking](Core-Systems/Networking) - Connection to server
