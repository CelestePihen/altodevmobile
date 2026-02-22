# Screens

> **IA generated documentation reviewed by [@ThFoxY](https://github.com/ThFoxY)!**

This folder contains all the screens of the Alto application.

---

## `home_screen.dart` — `HomeScreen`

**Status : UI done ✅ | Backend : not connected ⏳**

Entry point of the app after launch. Displays the Alto logo, the app name and two action buttons.

| Button | Action | Backend needed |
|---|---|---|
| `Scan a QR code` | Should navigate to the scan screen | ⏳ Route not yet created |
| `Create a connection` | Navigates to `/pairing` → `InitPairingScreen` | ✅ Route done via `go_router` |

**Nothing to do on this screen for now.**

---

## `pairing_screen.dart` — `InitPairingScreen`

**Status : UI done ✅ | Backend : mock only ⏳**

Displays the user's personal QR code so another user can scan it to initiate a secure pairing.

### Current behaviour (mock/UI only)
- A **spinner** (`CircularProgressIndicator`) is shown during 2 simulated seconds, representing QR code generation.
- After the delay, a **QR code** is displayed via `QrCodeDisplay` with a mocked payload string.
- A **`PairingStatusIndicator`** shows `"Waiting for scan..."` with animated dots. The status is currently static.
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
- Map the API response to the `PairingStatus` enum (see `widgets/qrcode/pairing_status_indicator.dart`).
- Cancel the timer when status reaches `connected` or `finishing`.
- **Also cancel `_expiryTimer`** when a scan is detected (status is no longer `waiting`).

```dart
// Expected GET /pairing response shape (to be confirmed with backend)
{ "status": "waiting" | "connected" | "finishing" }
```

#### 3. Navigation after pairing
Once status is confirmed as `finishing` (or a subsequent `done` status), navigate to the relation screen.
