# Screens

> **IA generated documentation reviewed by [@ThFoxY](https://github.com/ThFoxY)!**

This folder contains all the screens of the Alto application.

---

## `home_screen.dart` — `HomeScreen`

**Status : UI done ✅ | Backend : not connected ⏳**

Entry point of the app after launch. Displays the Alto logo, the app name and two action buttons.

| Button                | Action                                          | Backend needed               |
|-----------------------|-------------------------------------------------|------------------------------|
| `Scan a QR code`      | Navigates to `/scan` → `ScanPairingScreen`      | ✅ Route done via `go_router` |
| `Create a connection` | Navigates to `/pairing` → `InitPairingScreen`   | ✅ Route done via `go_router` |

**Nothing to do on this screen for now.**

---

## `pairing_screen.dart` — `InitPairingScreen`

**Status : UI done ✅ | Backend : mock only ⏳**

Displays the user's personal QR code so another user can scan it to initiate a secure pairing.

### Current behaviour (mock/UI only)

- A **spinner** (`CircularProgressIndicator`) is shown during 2 simulated seconds, representing QR
  code generation.
- After the delay, a **QR code** is displayed via `QrCodeDisplay` with a mocked payload string.
- A **`PairingStatusIndicator`** shows `"Waiting for scan..."` with animated dots. The status is
  currently static.
- A **2-minute expiry timer** starts automatically after the QR code is displayed.
    - On expiry, an `ErrorDisplay` modal appears (`ErrorType.timeout`) with two action buttons:
        - **Retry** → dismisses the modal, resets the timer and generates a fresh QR code.
        - **Go back** → dismisses the modal and navigates back to `HomeScreen`.

### What the backend developer must implement [@CelestePihen](https://github.com/CelestePihen)

#### 1. QR code payload — `_generateQrData()` inside `_startPairing()`

Replace the `Future.delayed` mock with:

- Retrieve or generate the user's **UUID**.
- Generate an **RSA key pair** (see `crypto/` folder).
- Store the **private key** securely using `flutter_secure_storage`.
- Build `_qrData` as a structured payload (e.g. JSON) containing the UUID and the **public key**.

```dart
// Expected payload shape (to be confirmed with backend)
{
  "uuid": "<user-uuid>",
  "publicKey": "<rsa-public-key-base64>"
}
```

#### 2. Pairing status polling — `_status`

Replace the static `final PairingStatus _status = PairingStatus.waiting` with:

- A `setState`-driven variable: `PairingStatus _status = PairingStatus.waiting`.
- A polling loop (`Timer.periodic`) calling `GET /pairing` every ~2 seconds.
- Map the API response to the `PairingStatus` enum (see
  `widgets/qrcode/pairing_status_indicator.dart`).
- Cancel the timer when status reaches `connected` or `finishing`.
- **Also cancel `_expiryTimer`** when a scan is detected (status is no longer `waiting`).

```dart
// Expected GET /pairing response shape (to be confirmed with backend)
{ "status": "waiting" | "connected" | "finishing" }
```

#### 3. Navigation after pairing

Once status is confirmed as `finishing` (or a subsequent `done` status), navigate to the relation
screen.

---

## `scanning_screen.dart` — `ScanPairingScreen`

**Status : UI done ✅ | Backend : mock only ⏳**

Displays the camera viewfinder so the user can scan another user's QR code to initiate pairing.

### Current behaviour (mock/UI only)

- A **`MobileScanner`** widget displays the rear camera feed inside a rounded frame.
- A **`ScanningStatusIndicator`** reacts to the camera events:
    - `noQrCode` → `"No QR code detected"` (default)
    - `scanning` → `"Scanning..."` with animated dots (briefly shown on detection)
    - `validQrCode` → `"Valid QR code detected"` (shown after successful decode)
- When a QR code is detected, an **`InfoDisplay`** modal appears with the raw scanned content and
  two buttons:
    - **Confirm** → dismisses the modal. *(Backend: trigger pairing confirmation here)*
    - **Cancel** → dismisses the modal and resets the scanner to allow a new scan.
- If the camera is unavailable, a fallback UI is shown (icon + message).

### What the backend developer must implement [@CelestePihen](https://github.com/CelestePihen)

#### 1. Camera permission handling

On first launch, request camera permission before the screen loads.
If denied, call:

```dart
showErrorDisplay(
  context: context,
  type: ErrorType.permission,
  message: 'Camera access is required to scan QR codes.',
  position: ModalPosition.center,
  onOk: () => Navigator.of(context).pop(),
);
```

#### 2. QR payload validation — `_onDetect()`

After receiving `rawValue`, validate its format before showing `InfoDisplay`:

- Parse the payload (expected JSON or `uuid::publicKey` format — to confirm with backend).
- If invalid → show `ErrorDisplay(ErrorType.unknown, ...)` instead of `InfoDisplay`.
- If valid → parse into a model (see `models/` folder) and display readable fields in `InfoDisplay`.

```dart
// Expected QR payload shape (to be confirmed with backend)
{
  "uuid": "<user-uuid>",
  "publicKey": "<rsa-public-key-base64>"
}
```

#### 3. Pairing confirmation — `onConfirm` in `_showScannedDataModal()`

When the user taps **Confirm**:

- Send a pairing request to the backend using the scanned UUID and public key.
- On success → navigate to the relation screen.
- On failure → show `ErrorDisplay(ErrorType.network, ...)`.
