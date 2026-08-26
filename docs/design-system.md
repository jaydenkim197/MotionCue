# MotionCue Design System

> Status: active product-design baseline  
> Applies to: Windows desktop app, iOS companion app, future study screens, onboarding, and documentation screenshots  
> Last updated: 2026-08-26

## 1. Purpose

MotionCue reduces visual discomfort while a person uses a laptop in a moving vehicle. Its interface must therefore feel calm, light, immediately understandable, and never visually demanding.

The reference is the user-supplied archive `C:\Users\sukhe\Downloads\gradient-ui-ux-elements-collection.zip` (`5883359.jpg`, EPS, AI). The reference uses a soft lavender background, white rounded surfaces, diffuse shadows, and one periwinkle accent. MotionCue adopts that visual language rather than copying the source artwork or bundling its assets.

This document is the source of truth for all future visual work. Before changing any MotionCue screen, inspect the applicable sections here. If a change deliberately differs, record the reason in `docs/development-log.md` and update this document in the same change.

## 2. Product principles

1. **One clear next action.** The default screen must tell the user what to do in one glance. For MotionCue this is usually connect the phone, or confirm that it is connected.
2. **Calm over clever.** MotionCue is used during travel. Avoid dense controls, flashing status, aggressive error colors, unnecessary animation, or analytics-like dashboards.
3. **Progressive disclosure.** Daily controls are visible; research, diagnostics, virtual replay, raw values, and recovery tools are collapsed or explicitly advanced.
4. **State is more valuable than decoration.** A user should understand connected / waiting / unavailable / active without reading a long log.
5. **One product, two native platforms.** Windows and iOS share layout logic, colors, language, and component roles. They use their platform’s accessible native typography and interaction conventions.
6. **No false certainty.** Motion sensing, BLE, and background operation can be intermittent. Status copy must be specific without promising guarantees.

## 3. Brand foundations

### 3.1 Color tokens

| Token | Value | Use |
|---|---:|---|
| `canvas` | `#F4F6FC` | App/page background |
| `surface` | `#FFFFFF` | Cards, popovers, primary controls |
| `surface-subtle` | `#F3F5FA` | Unselected segments, checkboxes, quiet controls |
| `surface-hover` | `#F0F2F8` | Hovered quiet controls and fields |
| `accent` | `#6670E8` | Primary action, active selection, key focus |
| `accent-strong` | `#525CD7` | Selected menu item foreground, emphasis when needed |
| `accent-soft` | `#EEF0FF` | Status panel, selected/hovered supporting surface |
| `accent-selected` | `#E5E8FF` | Selected popup row |
| `text` | `#172033` | Headings and primary content |
| `text-secondary` | `#41495F` | Standard control labels |
| `text-muted` | `#737B91` | Help text, metadata, inactive information |
| `border` | `#E3E6EF` | Fields and popovers |
| `border-strong` | `#CDD2E1` | Unchecked control outline |
| `danger` | `#B42318` | Emergency stop and destructive safety actions only |
| `danger-soft` | `#FFF0F0` | Emergency-stop surface only |

Rules:

- Use `accent` as the only everyday saturated color. Do not introduce a second brand color for ordinary features.
- Do not use red for disconnected, scanning, or recoverable BLE states; they are not emergencies. Use neutral text or the `accent-soft` status surface.
- White dots on a bright desktop remain an accessibility choice in the overlay, not a branding choice. The Settings UI continues to use the token palette above.

### 3.2 Typography

| Role | Windows | iOS | Size / weight |
|---|---|---|---|
| Product title | Segoe UI | SF Pro Display | 24 pt, semibold |
| Page/card heading | Segoe UI | SF Pro Display | 17 pt, semibold |
| Primary body/control | Segoe UI | SF Pro Text | 14–15 pt, regular or semibold where actionable |
| Supporting text | Segoe UI | SF Pro Text | 12–13 pt, regular |
| Metadata / labels | Segoe UI | SF Pro Text | 10–12 pt, semibold |
| Diagnostics | Consolas | SF Mono | 11–12 pt, regular |

The supplied reference lists Nunito, but MotionCue does not package or download it. Use the platform system font instead: it avoids an install dependency, preserves rendering quality, and feels native on both devices.

### 3.3 Geometry and elevation

| Token | Value | Use |
|---|---:|---|
| `space-1` | 4 px | Label to helper text |
| `space-2` | 8 px | Related controls |
| `space-3` | 12 px | Small internal separation |
| `space-4` | 16 px | Card content grouping |
| `space-5` | 22–24 px | Card padding / major separation |
| `space-6` | 32–34 px | Page margins |
| `radius-control` | 9–10 px | Buttons, fields, segmented controls |
| `radius-status` | 12–13 px | Status panels and small labels |
| `radius-card` | 18 px | Major cards |
| `shadow-card` | `#243052`, blur 18, depth 3, opacity 0.09 | Major cards only |
| `shadow-popover` | `#243052`, blur 18, depth 4, opacity 0.14 | Dropdown/popup only |

Use soft diffuse elevation. Do not use hard borders plus strong shadows on the same card. Use either a faint border or a shadow, with shadow preferred for major cards.

## 4. Information architecture

### 4.1 Everyday user view

The default screen has exactly three primary areas, in this order:

1. **Connection** — phone discovery, connection, reconnection state, and the single suggested action.
2. **Motion cues** — `Automatic`, `Always on`, and `Off`.
3. **Visual style** — pattern, color, dot size, and dot density.

The Windows layout may show the live status card in a narrow right column. The iOS layout uses a single vertical column and shows the sensor/advertising status at the top.

### 4.2 Advanced view

Advanced content is never interleaved with daily settings.

- **Research session:** collapsed by default; available to researchers without a hidden gesture.
- **Diagnostics and test tools:** hidden until Developer Mode is explicitly enabled; then kept inside its own collapsed card.
- **Raw logs, UUIDs, virtual replay, calibration values:** diagnostics only.
- **Emergency stop:** available only during an active research session; it is visually distinct through `danger` tokens.

### 4.3 Connection UX target

The intended everyday flow is:

```text
Open MotionCue Sensor on iPhone
        ↓
Windows MotionCue remembers / discovers it
        ↓
Connected — MotionCue works automatically
```

The Scan and Connect controls are necessary for setup and recovery, but should not dominate a connected user's routine. Future improvements must favor remembered-sensor reconnection and one-line recovery guidance over repeated manual device selection.

## 5. Component specifications

### 5.0 Compact consumer UI rule

- Do not enlarge ordinary status copy into child-oriented or senior-mode presentation. Use normal platform text sizes and reserve large type for the product title only.
- The default screen shows only the current state and the single next action. Connection switches, background notes, raw counters, and diagnostics belong in a clearly accessible detail view.
- Short text placed inside a pill, button, metric tile, or compact card row must remain on one line. Shorten the label first; if space is still limited, use modest scaling or truncation rather than an awkward line break inside the shape.
- Explanatory paragraphs must not be placed inside several competing cards on the default screen. Keep detailed explanations in the detail view where they can use full-width rows with clear hierarchy.

### 5.1 App header

- 46 px rounded-square product mark with `accent` fill and a white `M`.
- Product name on the left; one short descriptive line below it.
- A compact status pill on the right: 8 px accent dot plus a direct state phrase.
- Do not put settings icons, account controls, or decorative graphics in the header.

### 5.2 Cards

- Background: `surface`; radius: `radius-card`; padding: `space-5`.
- One card represents one task. A card must have a clear title and at most one helper sentence above controls.
- Keep controls aligned to a stable grid. Avoid placing a dense table inside a daily-use card.
- Use meaningful, specific titles: `Connect your phone`, not `Bluetooth settings`.

### 5.3 Buttons

| Type | Appearance | Examples |
|---|---|---|
| Primary | `accent` fill, white semibold label | Connect, Start |
| Quiet | `surface-hover` fill, dark label | Scan, Disconnect, Stop & save |
| Danger | `danger-soft` fill, `danger` label | Emergency stop |

- Radius: `radius-control`; minimum height: 38–42 px; horizontal padding: 15 px.
- Use verbs. Avoid technical nouns alone (`BLE`, `Action`, `Execute`).
- One primary button per card/group. Do not style ordinary secondary actions as primary.
- Disabled state lowers opacity; it must remain legible and should explain why through nearby helper text when ambiguity is likely.

### 5.4 Segmented choices

- Use for mutually exclusive choices with 2–3 options only.
- Unselected: `surface-subtle`, secondary text.
- Selected: `accent`, white semibold text.
- Typical labels: `Automatic / Always on / Off`, `Calm / Dynamic`.
- Do not use segmented controls for long lists, research conditions, or device selection.

### 5.5 Dropdowns

- Field: `surface-subtle`, `border`, 10 px radius, 42 px minimum height.
- Trailing chevron: muted, centered in a 40 px tap/click target.
- Keyboard focus: 2 px `accent` ring/border.
- Popup: white surface, 10 px radius, `shadow-popover`, 5 px separation from field.
- Item padding: 12 px horizontal, 9 px vertical. Hover uses `accent-soft`; selection uses `accent-selected` with `accent-strong` text.
- Never fall back to the browser/Windows default bevel, gradient, or square menu appearance.

### 5.6 Checkboxes

- 20 × 20 px rounded square, 6 px radius.
- Unchecked: `surface-subtle`, `border-strong` outline.
- Checked: `accent` fill with 2.2 px white rounded check mark.
- Label sits 9 px from the control and uses `text-secondary`.
- Use checkboxes only for independent binary preferences (`Larger dots`, `More dots`, `Start with Windows`). Use a switch only when an immediate system on/off state is the primary meaning.

### 5.7 Status panels

- Use a small uppercase category label (`SENSOR`, `CONNECTION`) in `accent-strong`.
- Follow with one short human-readable state, not raw diagnostics.
- Background: `accent-soft`; radius: `radius-status`; padding: 15 px.
- Recommended copy:

| State | User-facing copy |
|---|---|
| No phone selected | `Open MotionCue Sensor on your iPhone, then scan.` |
| Discovering | `Looking for nearby MotionCue Sensor…` |
| Ready to connect | `iPhone found — connect when ready.` |
| Connected | `Phone connected · Motion cues are ready.` |
| Stream inactive | `Connected, waiting for motion data.` |
| Recoverable loss | `Phone connection paused. Keep the Sensor app open, then reconnect.` |
| Simulation | `Test signal active.` |

Do not expose BLE PDU size, UUIDs, watchdog status, timestamps, or estimator gains in the everyday status panel.

### 5.8 Expanders

- Use one plain title row with a chevron and 16–18 px card-like vertical breathing room.
- Closed by default unless the user has just started a relevant task.
- The collapsed title must communicate what is inside (`Research session`, `Diagnostics & test tools`).
- Never place critical connection recovery controls exclusively inside an expander.
- Expanding content may increase only the vertical scroll range. It must not resize the application window, change the desktop layout width, or alter the width allocation of neighboring primary cards.

### 5.9 Overlay cues

- The overlay remains intentionally quiet: edge-located dots only, no panel, text, controls, or persistent branding.
- The overlay should respect the configured color, size, density, motion mode, and failsafe visibility state.
- Do not import the card/shadow visual language into the cue overlay; it is a different surface with a different cognitive role.

## 6. Platform implementation guidance

### 6.1 Windows WPF

- Keep shared tokens close to `App.xaml` or the relevant window resource dictionary; avoid one-off literal colors in new views.
- Reuse templates for `Button`, `ComboBox`, `ComboBoxItem`, `CheckBox`, and segmented `RadioButton` rather than mixing Windows defaults with custom cards.
- Maintain keyboard focus visibility and keyboard operation for all controls. Custom appearance must not remove accessibility names, selection behavior, or keyboard navigation.
- The Settings window supports a responsive two-column layout at normal desktop width and a readable single-column/scrollable layout when narrow.

### 6.2 iOS SwiftUI

- Use `Color` assets named after the tokens above. Do not hard-code unrelated per-screen colors.
- Use `RoundedRectangle(cornerRadius:)` with the documented radii; use restrained `.shadow` equivalent to `shadow-card`.
- Use SF Symbols only when an icon communicates faster than text. Prefer `iphone`, `dot.radiowaves.left.and.right`, `checkmark`, and `chevron.down` only where their meaning is conventional.
- Respect Dynamic Type, VoiceOver labels, high-contrast settings, safe areas, and the iOS 44 pt minimum tap target.
- iOS primary screen hierarchy: phone sensor/advertising state → automatic sending state → simple help/recovery. Do not reproduce Windows research diagnostics on the consumer companion screen.

## 7. Motion and feedback

- State transitions may use 150–220 ms ease-out opacity/color changes only.
- Never animate cue settings in a way that competes with the cue overlay itself.
- Avoid pulsing, bouncing, flashing, auto-scrolling logs, or continuous spinners except during a clearly bounded scan/connect action.
- When a connection changes, update the status phrase and the status-dot color/appearance; do not show a modal unless user action is required.
- Use a short haptic confirmation on iOS only for explicit user actions such as starting transmission, not for each sensor frame or automatic reconnect.

## 8. Accessibility and safety

- Meet at least WCAG AA contrast for text and interactive controls where platform rendering allows.
- Do not encode a state with color alone; pair it with plain-language text and an icon/shape when appropriate.
- Never use small low-contrast helper text as the only explanation for an error that blocks the user.
- Keep touch/click targets at least 38–42 px on Windows and 44 pt on iOS.
- Preserve `Ctrl+Shift+F12` as the active-study emergency stop, but explain it only inside research UI. It is not consumer-facing.
- Privacy wording is short and factual: `Local processing · no account · no telemetry`. Do not claim that data is not collected unless the implementation enforces it.

## 9. Content and naming rules

- Write in short sentence case. Use direct verbs: `Scan`, `Connect`, `Disconnect`, `Start session`.
- Prefer user terms over implementation terms: `phone sensor`, not `BLE peripheral`; `motion data`, not `SensorFrame`.
- Preserve technical names only in diagnostics and research documentation.
- Avoid marketing language, emojis, exclamation marks, and vague labels such as `Settings`, `Options`, `Action`, or `Status` when a specific label exists.
- Keep the main user interface English, matching the bachelor-thesis prototype scope. Korean research notes may remain in documentation.

## 10. Asset and licensing policy

- The supplied gradient UI archive is a visual reference, not an automatically approved runtime asset pack.
- Do not add its EPS, AI, or JPG to the shipped app unless its license, attribution, and intended distribution rights are verified.
- Do not rasterize the reference to create buttons, cards, icons, or backgrounds. Recreate generic geometry with native WPF/SwiftUI components.
- If a new icon/illustration is needed, use an appropriately licensed vector asset or a native SF Symbol/WPF geometry and record the source/license in the relevant change.

## 11. Design review checklist

Before considering a UI task complete, verify:

- [ ] The default screen shows the user’s next action within the first viewport.
- [ ] The screen uses only the documented color tokens and geometry.
- [ ] Controls do not visually revert to platform-default bevels, square corners, or unrelated accent colors.
- [ ] Connected, unavailable, and recovery states have concise human-readable copy.
- [ ] Research and diagnostics are not competing with daily user actions.
- [ ] Keyboard navigation/focus is intact on Windows; Dynamic Type/VoiceOver are considered on iOS.
- [ ] The screen is tested at its expected window/device size and no card or popup is clipped.
- [ ] The change and its verification result are recorded in `docs/development-log.md`.
