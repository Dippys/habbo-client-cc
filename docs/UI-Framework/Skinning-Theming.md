# Skinning/Theming

The Theming system provides visual styling for all UI elements, supporting multiple themes with dynamic property overrides, XML-based layouts, and customizable skin renderers.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         THEMING ARCHITECTURE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      ThemeManager                                  │   │
│  │                                                                       │   │
│  │  ┌─────────────────────────────────────────────────────────────┐  │   │
│  │  │                     THEMES                                    │  │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐   │  │   │
│  │  │  │  NONE    │  │ VOLTER   │  │ UBUNTU   │  │ ILLUMINA  │   │  │   │
│  │  │  │          │  │          │  │          │  │ _LIGHT/   │   │  │   │
│  │  │  │ (default)│  │          │  │          │  │ _DARK     │   │  │   │
│  │  │  └──────────┘  └──────────┘  └──────────┘  └────────────┘   │  │   │
│  │  │                                                                │  │   │
│  │  │  Property Defaults (per theme)                                 │  │   │
│  │  └─────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      SkinContainer                                   │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ Skin Renderers  │  │ Default Attrs   │  │ Window Layouts │   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - Bitmap        │  │ - color         │  │ - XML          │   │   │
│  │  │ - Fill          │  │ - blend         │  │ - elements     │   │   │
│  │  │ - Text          │  │ - thresholds    │  │ - children     │   │   │
│  │  │ - Shape         │  │ - size limits  │  │                 │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   XML Skin Definitions                              │   │
│  │                                                                       │   │
│  │  <window type="button" style="1" intent="button_white"           │   │
│  │        renderer="bitmap" color="0xFFFFFF">                          │   │
│  │      <states>...</states>                                           │   │
│  │  </window>                                                           │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ThemeManager

**File:** `src/com/sulake/habbo/window/theme/ThemeManager.as`

Central orchestrator for theming:

### Available Themes

| Theme | Style Range | Real Theme |
|-------|-------------|------------|
| `Theme.NONE` | 0 - uint.MAX | No |
| `Theme.ICON` | Dynamic | No |
| `Theme.LEGACY_BORDER` | 0-100 | No |
| `Theme.VOLTER` | 0-3 | Yes |
| `Theme.UBUNTU` | 3-8 | Yes |
| `Theme.ILLUMINA_LIGHT` | 100-200 | Yes |
| `Theme.ILLUMINA_DARK` | 200-300 | Yes |

### Key Methods

```actionscript
// Get style ID for theme/type
getStyle(type:String, styleId:uint, intent:String):uint

// Get theme and intent for window
getThemeAndIntent(windowType:uint, styleId:uint):Object

// Get available intents
getIntents(windowType:uint, intent:String, styleId:uint):Array

// Get property defaults
getPropertyDefaults(windowType:uint):IPropertyMap
```

## Theme Class

**File:** `src/com/sulake/habbo/window/theme/Theme.as`

```actionscript
public class Theme
{
    private var _name:String;
    private var _isReal:Boolean;
    private var _baseStyle:uint;
    private var _styleCount:uint;
    private var _propertyDefaults:PropertyMap;
}
```

## SkinContainer

**File:** `src/com/sulake/core/window/graphics/SkinContainer.as`

Manages skin assets:

### Data Structures

```actionscript
_skinRendererTable:Dictionary   // windowType -> style -> ISkinRenderer
_defaultAttrTable:Dictionary   // windowType -> style -> DefaultAttStruct
_windowLayoutTable:Dictionary // windowType -> style -> XML
_intentTable:Dictionary        // windowType -> style -> intent
```

### Window States

| State | Description |
|-------|-------------|
| `LOCKED` | Window is locked |
| `DISABLED` | Window is disabled |
| `PRESSED` | Button/control pressed |
| `SELECTED` | Item selected |
| `HOVERING` | Mouse over |
| `FOCUSED` | Has focus |
| `ACTIVE` | Currently active |
| `DEFAULT` | Default state |

## XML Layout System

### XML Structure

```xml
<window type="button" style="1" intent="button_white" 
        asset="habbo_skin_button" layout="button_layout" 
        window_layout="habbo_window_layout_button_xml"
        renderer="bitmap" blend="1" color="0xFFFFFF">
    <states>
        <!-- State definitions -->
    </states>
</window>
```

### Attributes

| Attribute | Description |
|-----------|-------------|
| `type` | Window type |
| `style` | Style ID |
| `intent` | Theme intent matching |
| `asset` | Asset name |
| `layout` | Layout name |
| `renderer` | Renderer type (bitmap, fill, text, shape) |
| `color` | Color value |
| `blend` | Blend factor |

### Renderer Types

| Type | Renderer Class |
|------|----------------|
| `bitmap` | BitmapSkinRenderer |
| `fill` | FillSkinRenderer |
| `text` | TextSkinRenderer |
| `shape` | ShapeSkinRenderer |
| `null` | NullSkinRenderer |

## Property System

### PropertyKeys
**File:** `src/com/sulake/core/window/theme/PropertyKeys.as`

80+ customizable properties:

### Text Properties

| Key | Type | Description |
|-----|------|-------------|
| `TEXT_COLOR` | HEX | Text color |
| `TEXT_STYLE` | ENUM | Text style |
| `FONT_FACE` | STRING | Font family |
| `FONT_SIZE` | INT | Font size |
| `BOLD` | BOOLEAN | Bold text |
| `ITALIC` | BOOLEAN | Italic text |

### Layout Properties

| Key | Type | Description |
|-----|------|-------------|
| `MARGIN_LEFT` | INT | Left margin |
| `MARGIN_TOP` | INT | Top margin |
| `PADDING_HORIZONTAL` | INT | Horizontal padding |
| `SPACING` | INT | Element spacing |

### Behavior Properties

| Key | Type | Description |
|-----|------|-------------|
| `SELECTABLE` | BOOLEAN | Allow selection |
| `EDITABLE` | BOOLEAN | Allow editing |
| `TOOL_TIP_CAPTION` | STRING | Tooltip text |
| `TOOL_TIP_DELAY` | INT | Tooltip delay |

### Default Attribute Structure

```actionscript
threshold:uint    // State change threshold
background:Boolean // Has background
blend:Number       // Blend factor
color:uint         // Color
width_min/max     // Size constraints
height_min/max    // Size constraints
```

## Theme Initialization

```actionscript
// Base defaults (all themes)
properties.addBoolean(PropertyKeys.ALWAYS_SHOW_SELECTION, false);
properties.addEnumeration(PropertyKeys.ANTIALIAS_TYPE, AntiAliasType.NORMAL);
properties.addString(PropertyKeys.ASSET_URI, null);

// Theme-specific overrides
// Volter theme
this._themes[Theme.VOLTER] = new Theme(Theme.VOLTER, true, 0, 3, properties.clone());

// Ubuntu theme
propertyDefaults = properties.clone();
propertyDefaults.addEnumeration(PropertyKeys.ANTIALIAS_TYPE, AntiAliasType.ADVANCED);

// Illumina Light/Dark themes
propertyDefaults.addHex(PropertyKeys.ETCHING_COLOR, 3003121663);
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/window/theme/ThemeManager.as` | Theme orchestration |
| `src/com/sulake/habbo/window/theme/Theme.as` | Theme definition |
| `src/com/sulake/core/window/graphics/SkinContainer.as` | Skin assets |
| `src/com/sulake/habbo/window/utils/SkinParserUtil.as` | XML parsing |
| `src/com/sulake/core/window/theme/PropertyMap.as` | Properties |
| `src/com/sulake/core/window/theme/PropertyKeys.as` | Property constants |

## Phase 3 Complete Summary

UI Framework documentation created:
- [Window Manager](docs/UI-Framework/Window-Manager.md) ✅
- [Widget System](docs/UI-Framework/Widget-System.md) ✅
- [Event Handling](docs/UI-Framework/Event-Handling.md) ✅
- [Skinning/Theming](docs/UI-Framework/Skinning-Theming.md) ✅