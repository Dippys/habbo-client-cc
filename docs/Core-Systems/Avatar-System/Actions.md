# Avatar Actions

The Avatar Actions system defines how avatars animate and display different states - from basic postures like standing and sitting, to gestures like waving and smiling, to effects like floating and sleeping.

## Action System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ACTION SYSTEM ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AvatarAction (Enum)                               │   │
│  │                                                                       │   │
│  │  - POSTURE: std, sit, mv, lay, swim, float                          │   │
│  │  - GESTURE: sml, agr, srp, sad                                      │   │
│  │  - EXPRESSION: wave, blow, laugh, cry, idle, respect               │   │
│  │  - EFFECT: fx33, fx34, ...                                          │   │
│  │  - DANCE: 1, 2, 3, 4                                                 │   │
│  │  - SIGN: 0-7                                                        │   │
│  │  - TALK, TYPING, SLEEP, MUTED                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   AvatarActionManager                                │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ ActionDefinition│  │ ActiveActionData│  │   Animation     │   │   │
│  │  │                 │  │                  │  │   Manager       │   │   │
│  │  │ - state         │  │ - actionType    │  │                 │   │   │
│  │  │ - geometryType  │  │ - actionId      │  │ - Animations   │   │   │
│  │  │ - main          │  │ - activePart    │  │ - Frames       │   │   │
│  │  │ - canvasOffset  │  │ - parameters    │  │ - Layer data   │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     AvatarImage                                     │   │
│  │                                                                       │   │
│  │  appendAction(POSTURE, "std")                                      │   │
│  │  appendAction(GESTURE, "sml")                                      │   │
│  │  appendAction(EXPRESSION, "wave")                                  │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## AvatarAction Enum

**File:** `src/com/sulake/habbo/avatar/enum/AvatarAction.as`

### Posture Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `POSTURE_STAND` | `"std"` | Standing default |
| `POSTURE_SIT` | `"sit"` | Sitting |
| `POSTURE_WALK` | `"mv"` | Walking/moving |
| `POSTURE_LAY` | `"lay"` | Lying down |
| `POSTURE_SWIM` | `"swim"` | Swimming |
| `POSTURE_FLOAT` | `"float"` | Floating (effect) |

### Gesture Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `GESTURE_SMILE` | `"sml"` | Smile |
| `GESTURE_AGGRAVATED` | `"agr"` | Angry |
| `GESTURE_SURPRISED` | `"srp"` | Surprised |
| `GESTURE_SAD` | `"sad"` | Sad |

### Expression Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `EXPRESSION_WAVE` | `"wave"` | Wave hand |
| `EXPRESSION_BLOW_A_KISS` | `"blow"` | Blow kiss |
| `EXPRESSION_LAUGH` | `"laugh"` | Laugh |
| `EXPRESSION_CRY` | `"cry"` | Cry |
| `EXPRESSION_IDLE` | `"idle"` | Idle animation |
| `EXPRESSION_RESPECT` | `"respect"` | Respect gesture |

### Other Action Types

| Constant | Value | Description |
|----------|-------|-------------|
| `EFFECT` | `"fx"` | Visual effect |
| `DANCE` | `"dance"` | Dance animation |
| `SIGN` | `"sign"` | Hand sign (0-7) |
| `TALK` | `"talk"` | Talking animation |
| `TYPING` | `"typing"` | Typing indicator |
| `SLEEP` | `"Sleep"` | Sleeping state |
| `MUTED` | `"muted"` | Muted indicator |
| `CARRY_OBJECT` | `"cri"` | Carried item |
| `USE_OBJECT` | `"usei"` | Using item |

### Expression Durations

```actionscript
// Duration in milliseconds
getExpressionTime(EXPRESSION_WAVE)         // 5000
getExpressionTime(EXPRESSION_BLOW_A_KISS)  // 1400
getExpressionTime(EXPRESSION_LAUGH)       // 2000
getExpressionTime(EXPRESSION_CRY)         // 3000
getExpressionTime(EXPRESSION_RESPECT)     // 3000
```

## AvatarActionManager

**File:** `src/com/sulake/habbo/avatar/actions/AvatarActionManager.as`

Manages action definitions from XML:

```actionscript
public class AvatarActionManager extends Component
{
    private var _actions:Dictionary;
    private var _defaultAction:ActionDefinition;
}
```

### Action Definition XML

```xml
<action id="std" state="std" main="1" geometrytype="vertical">
    <offsets>
        <offset x="0" y="0">full</offset>
    </offsets>
</action>

<action id="sit" state="sit" main="1" geometrytype="sitting">
    <offsets>
        <offset x="0" y="8">full</offset>
    </offsets>
</action>
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `updateActions(xml)` | Parse action definitions from XML |
| `getDefaultAction()` | Get default posture |
| `isHeadTurnPreventedByAction()` | Check if action blocks head turning |
| `getActionOffsets()` | Get canvas offsets for direction |

## ActionDefinition

**File:** `src/com/sulake/habbo/avatar/actions/ActionDefinition.as`

```actionscript
public class ActionDefinition
{
    private var _state:String;           // Action state (e.g., "std", "sit")
    private var _geometryType:String;   // "vertical", "sitting", "swim"
    private var _main:Boolean;          // Is main action
    private var _active:Boolean;        // Is active
    private var _canvasOffsets:Map;    // Direction -> offset
}
```

## ActiveActionData

**File:** `src/com/sulake/habbo/avatar/actions/ActiveActionData.as`

```actionscript
public class ActiveActionData
{
    private var _action:ActionDefinition;
    private var _actionType:String;
    private var _actionId:String;
    private var _startTime:int;
}
```

## Animation System

### AnimationManager

**File:** `src/com/sulake/habbo/avatar/animation/AnimationManager.as`

Manages all animations:

```actionscript
public class AnimationManager implements IAnimationManager
{
    private var _animations:Dictionary;
}
```

### Animation

**File:** `src/com/sulake/habbo/avatar/animation/Animation.as`

From XML configuration:

```xml
<animation id="std">
    <sprite>
        <layer id="ch">
            <frameindex>0</frameindex>
        </layer>
        <layer id="hd">
            <frameindex>0</frameindex>
        </layer>
    </sprite>
    <direction>
        <frameindex>0</frameindex>
    </direction>
    <frame>
        <bodypart id="ch">
            <frameindex>1</frameindex>
        </bodypart>
    </frame>
</animation>
```

### AnimationLayerData

```actionscript
public class AnimationLayerData
{
    private var _id:String;           // Layer ID (body part)
    private var _frameIndex:int;      // Frame to display
    private var _dx:int;             // X offset
    private var _dy:int;             // Y offset
    private var _dz:Number;          // Z offset (depth)
}
```

## AvatarImage Action Integration

### Appending Actions

```actionscript
// In AvatarImage
public function appendAction(k:String, ..._args):void
{
    // k: Action type (e.g., POSTURE, GESTURE)
    // _args: Action value (e.g., "std", "sml")
    
    _activeActionData = new ActiveActionData(
        _actionManager.getActionDefinition(k, _args[0]),
        k,
        _args[0]
    );
}
```

### Action Priorities

Multiple actions can be active simultaneously. Priority order:
1. EFFECT (effects override everything)
2. EXPRESSION
3. GESTURE
4. POSTURE (base state)

### Frame Updates

```actionscript
// Each frame, increment
_frameCounter++;

// Get animation frame
var frame:int = _animationManager.getFrame(
    _activeActionData.actionId,
    _frameCounter
);

// Get image for current frame
var image:BitmapData = getImage(AvatarSetType.FULL, false, 1.0);
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/avatar/enum/AvatarAction.as` | Action constants |
| `src/com/sulake/habbo/avatar/actions/AvatarActionManager.as` | Action management |
| `src/com/sulake/habbo/avatar/actions/ActionDefinition.as` | Action definition |
| `src/com/sulake/habbo/avatar/actions/ActiveActionData.as` | Active action data |
| `src/com/sulake/habbo/avatar/animation/AnimationManager.as` | Animation management |
| `src/com/sulake/habbo/avatar/animation/Animation.as` | Animation definition |
| `src/com/sulake/habbo/avatar/animation/AnimationLayerData.as` | Animation layer |

## Next Steps

- [Avatar Caching](Core-Systems/Avatar-System/Caching) - Image cache implementation
- [Furniture Architecture](Core-Systems/Furniture-System/Architecture) - Furniture system