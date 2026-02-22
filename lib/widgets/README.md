# Widgets

> **IA generated documentation reviewed by [@ThFoxY](https://github.com/ThFoxY)!**

This folder contains all reusable UI components of the Alto application.
Widgets are purely presentational — they receive data via their constructor and display it.
**No widget here makes any API call or holds business logic.**

---

## `common/`

General-purpose widgets reusable across multiple screens.

| File | Widget | Description |
|---|---|---|
| `button_types.dart` | `ButtonSize` | Enum defining button sizes (S, M, L) with computed width/height |
| `primary_button.dart` | `PrimaryButton` | White filled button with black border, supports optional icon |
| `secondary_button.dart` | `SecondaryButton` | Outlined secondary button, supports optional icon |
| `animated_dots.dart` | `AnimatedDots` | Three dots animating one by one in a loop — used for polling states |

### `AnimatedDots` — usage
```dart
Row(
  children: [
    Text('Waiting for scan'),
    AnimatedDots(color: Colors.white, fontSize: 24),
  ],
)
```
**No backend interaction. Purely visual.**

---

## `modals/`

Reusable modal overlays displayed on top of any screen.

| File | Widget | Helper function | Description |
|---|---|---|---|
| `error_display.dart` | `ErrorDisplay` | `showErrorDisplay()` | Centered overlay with icon, message and configurable action buttons |

### `ErrorType` enum — available error types

| Value | Icon displayed | Use case |
|---|---|---|
| `timeout` | 🕐 Clock | QR code expired, session timeout |
| `network` | 📶 Wifi off | No internet connection |
| `permission` | 🔒 Lock | Missing camera or storage permission |
| `unknown` | ❗ Exclamation | Unexpected/generic error |

### `ModalPosition` enum — available positions

| Value | Position on screen |
|---|---|
| `top` | Near the top (below status bar) |
| `center` | Centered vertically |
| `bottom` | Near the bottom (above nav bar) |

### `showErrorDisplay()` — usage

Use the helper function to display the modal from any screen:

```dart
showErrorDisplay(
  context: context,
  type: ErrorType.timeout,
  message: 'Your QR code is no longer valid for security reasons.',
  position: ModalPosition.center,
  onRetry: _restartPairing,           // Optional — shows "Retry" button
  onGoBack: () => context.pop(),       // Optional — shows "Go back" button
  // onOk: ...                         // Optional — shows "Ok" button (default if no other button)
  // onCancel: ...                     // Optional — shows "Cancel" button
);
```

**Button visibility rules:**
- If **no custom callback** is provided → only **"Ok"** is shown (dismisses the modal).
- If **any custom callback** is provided → only buttons with a non-null callback are shown.
- **"Ok"** can always be forced by explicitly passing `onOk`.

**No backend interaction. Purely visual.**

---

## `qrcode/`

Widgets specific to the QR code pairing flow.

| File | Widget | Description |
|---|---|---|
| `qr_code_display.dart` | `QrCodeDisplay` | Renders a styled QR code inside a white rounded card + disclaimer |
| `pairing_status_indicator.dart` | `PairingStatusIndicator` | Displays a status label with animated dots for polling states |

### `QrCodeDisplay` — usage
```dart
QrCodeDisplay(data: '<uuid>::<publicKey>')
```
Receives a plain string as `data`. The **backend** is responsible for building this string (UUID + public key).

### `PairingStatusIndicator` — usage
```dart
PairingStatusIndicator(status: PairingStatus.waiting)
```

### `PairingStatus` enum — expected values

| Value | Label displayed | Animated dots | Triggered by |
|---|---|---|---|
| `waiting` | `Waiting for scan...` | ✅ Yes | Default — `GET /pairing` → `"waiting"` |
| `connected` | `Connection detected!` | ❌ No | `GET /pairing` → `"connected"` |
| `finishing` | `Finishing...` | ✅ Yes | `GET /pairing` → `"finishing"` |

**TODO [BACKEND]:** The `status` field in `InitPairingScreen` must be updated
via `setState` based on the `GET /pairing` polling result.
Map the API string response to the `PairingStatus` enum defined in `pairing_status_indicator.dart`.

---

## `relation/`

*(Empty — reserved for future relation management widgets.)*
