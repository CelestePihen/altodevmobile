# Widgets

> **IA generated documentation reviewed by [@ThFoxY](https://github.com/ThFoxY)!**

This folder contains all reusable UI components of the Alto application.
Widgets are purely presentational — they receive data via their constructor and display it.
**No widget here makes any API call or holds business logic.**

---

## `common/`

General-purpose widgets reusable across multiple screens.

| File                    | Widget            | Description                                                         |
|-------------------------|-------------------|---------------------------------------------------------------------|
| `button_types.dart`     | `ButtonSize`      | Enum defining button sizes (S, M, L) with computed width/height     |
| `primary_button.dart`   | `PrimaryButton`   | White filled button with black border, supports optional icon       |
| `secondary_button.dart` | `SecondaryButton` | Outlined secondary button, supports optional icon                   |
| `animated_dots.dart`    | `AnimatedDots`    | Three dots animating one by one in a loop — used for polling states |

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

| File                 | Widget         | Helper function      | Description                                                              |
|----------------------|----------------|----------------------|--------------------------------------------------------------------------|
| `error_display.dart` | `ErrorDisplay` | `showErrorDisplay()` | Overlay with icon, message and configurable action buttons for errors    |
| `info_display.dart`  | `InfoDisplay`  | `showInfoDisplay()`  | Overlay with icon, title, message body and Confirm/Cancel action buttons |

### `ErrorType` enum — available error types

| Value        | Icon displayed | Use case                             |
|--------------|----------------|--------------------------------------|
| `timeout`    | 🕐 Clock       | QR code expired, session timeout     |
| `network`    | 📶 Wifi off    | No internet connection               |
| `permission` | 🔒 Lock        | Missing camera or storage permission |
| `unknown`    | ❗ Exclamation  | Unexpected/generic error             |

### `ModalPosition` enum — available positions (`error_display.dart`)

| Value    | Position on screen              |
|----------|---------------------------------|
| `top`    | Near the top (below status bar) |
| `center` | Centered vertically             |
| `bottom` | Near the bottom (above nav bar) |

### `showErrorDisplay()` — usage

```dart
showErrorDisplay(
  context: context,
  type: ErrorType.timeout,
  message: 'Your QR code is no longer valid for security reasons.',
  position: ModalPosition.center,
  onRetry: _restartPairing,       // Optional — shows "Retry" button
  onGoBack: () => context.pop(),  // Optional — shows "Go back" button
  // onOk: ...                    // Optional — shows "Ok" button (default if no other button)
  // onCancel: ...                // Optional — shows "Cancel" button
);
```

**Button visibility rules:**

- If **no custom callback** is provided → only **"Ok"** is shown (dismisses the modal).
- If **any custom callback** is provided → only buttons with a non-null callback are shown.
- **"Ok"** can always be forced by explicitly passing `onOk`.

### `InfoModalPosition` enum — available positions (`info_display.dart`)

| Value    | Position on screen              |
|----------|---------------------------------|
| `top`    | Near the top (below status bar) |
| `center` | Centered vertically             |
| `bottom` | Near the bottom (above nav bar) |

### `showInfoDisplay()` — usage

```dart
showInfoDisplay(
  context: context,
  title: 'QR Code scanned!',
  message: 'UUID: ...\nPublic key: ...',
  position: InfoModalPosition.center,
  onConfirm: () { ... },  // Optional — shows "Confirm" button
  onCancel: () { ... },   // Optional — shows "Cancel" button
  // If neither is provided → "Ok" button is shown (dismisses the modal)
);
```

**No backend interaction. Purely visual.**

---

## `qrcode/`

Widgets specific to the QR code pairing flow.

| File                              | Widget                     | Description                                                          |
|-----------------------------------|----------------------------|----------------------------------------------------------------------|
| `qr_code_display.dart`            | `QrCodeDisplay`            | Renders a styled QR code inside a white rounded card + disclaimer    |
| `pairing_status_indicator.dart`   | `PairingStatusIndicator`   | Displays a pairing status label with animated dots for polling states |
| `scanning_status_indicator.dart`  | `ScanningStatusIndicator`  | Displays a scan status label with animated dots during scan          |

### `QrCodeDisplay` — usage

```dart
QrCodeDisplay(data: '<uuid>::<publicKey>')
```

Receives a plain string as `data`. The **backend** is responsible for building this string (UUID +
public key).

### `PairingStatusIndicator` — usage

```dart
PairingStatusIndicator(status: PairingStatus.waiting)
```

### `PairingStatus` enum — expected values

| Value       | Label displayed        | Animated dots | Triggered by                           |
|-------------|------------------------|---------------|----------------------------------------|
| `waiting`   | `Waiting for scan...`  | ✅ Yes         | Default — `GET /pairing` → `"waiting"` |
| `connected` | `Connection detected!` | ❌ No          | `GET /pairing` → `"connected"`         |
| `finishing` | `Finishing...`         | ✅ Yes         | `GET /pairing` → `"finishing"`         |

**TODO [BACKEND]:** The `status` field in `InitPairingScreen` must be updated via `setState` based
on the `GET /pairing` polling result.

### `ScanningStatusIndicator` — usage

```dart
ScanningStatusIndicator(status: ScanningStatus.noQrCode)
```

### `ScanningStatus` enum — expected values

| Value         | Label displayed            | Animated dots | Triggered by                                       |
|---------------|----------------------------|---------------|----------------------------------------------------|
| `noQrCode`    | `No QR code detected`      | ❌ No          | Default — no QR code in camera frame               |
| `scanning`    | `Scanning...`              | ✅ Yes         | A QR code is detected, decode in progress          |
| `validQrCode` | `Valid QR code detected`   | ❌ No          | QR code successfully decoded                       |

**TODO [BACKEND]:** After decode, validate the payload format and map it to a model (see `models/`).

---

## `relation/`

*(Empty — reserved for future relation management widgets.)*
