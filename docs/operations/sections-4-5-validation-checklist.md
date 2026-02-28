# Sections 4–5 manual validation checklist

Use this when running **Section 4 (Deep-link + QR)** and **Section 5 (Host iOS email-link E2E)** from the runbook.  
Reference: [runbook-execution-2026-02-20.md](runbook-execution-2026-02-20.md).

---

## Section 4 — Quick reference (join links)

**Where to get a valid join link**

1. Open the **Host** app and create or open a session (Lobby).
2. In the Lobby UI, use **Copy join link** / **Share link** (or the copy control next to the code).
3. The link has the form: `https://cb-reborn.web.app/join?mode=cloud&code=XXXX-XXXXXX` (code is the 10-character lobby code, e.g. `NEON-ABCDEF`).

**Valid link (for 4.1, 4.2, 4.4)**  
Use the link from the Host Lobby. Ensure the Host session is **online** (cloud link verified) so players can actually join.

**Invalid link (for 4.3, 4.5)**  
- Wrong or fake code: `https://cb-reborn.web.app/join?mode=cloud&code=FAKE-999999`  
- No code: `https://cb-reborn.web.app/join`  
- Malformed: `https://cb-reborn.web.app/join?code=`  

**QR codes**  
Generate a QR that encodes the exact join URL (e.g. [qr-code-generator.com](https://www.qr-code-generator.com) or any generator). Valid QR = valid join URL; invalid QR = any other URL or content.

**Deep-link behaviour (Player app)**  
- Links with `?code=...` are handled by the Player app (via `app_links`).  
- Cold start: open link while app is fully closed → app launches and should show connect/join for that code.  
- Warm start: open link while app is open → app should navigate to connect/join for that code (or show error if already in game).

---

## Before you start

- [ ] Player app build installed on test device(s) (Android and/or iOS as needed).
- [ ] Host app build installed (for Section 5: physical iOS device with Mail).
- [ ] One host session available (local or cloud) so join links/QR codes can be generated.
- [ ] Where to record evidence: _________________ (e.g. `docs/operations/evidence/` or screenshot folder).

---

## Section 4) Deep-link + QR validation

### 4.1 Cold-start deep-link join

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | Fully close the Player app (swipe away / force stop). | ☐ | |
| 2 | From Host (or another device), copy or generate a valid join link (local or cloud). | ☐ | |
| 3 | Open that link on the test device (e.g. paste in browser, or tap link in Notes/Mail). | ☐ | |
| 4 | Confirm the Player app launches (cold start) and lands on the correct join/claim flow for that game. | ☐ | |
| 5 | Complete join (claim player if needed) and confirm you see lobby or game as expected. | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### 4.2 Warm-start deep-link join

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | With Player app already open (e.g. on home or lobby), send a **different** valid join link to the device. | ☐ | |
| 2 | Open the link (same device or link from another app). | ☐ | |
| 3 | Confirm the app comes to foreground (or stays in foreground) and navigates to the join/claim flow for the new link. | ☐ | |
| 4 | Complete join and confirm correct session/lobby. | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### 4.3 Invalid / expired link handling

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | Create an invalid join URL (wrong code, malformed, or expired if your links have TTL). | ☐ | |
| 2 | Open it with the Player app closed (cold) or open (warm). | ☐ | |
| 3 | Confirm the app does not crash and shows a clear error or “invalid/expired link” state (no silent fail). | ☐ | |
| 4 | Confirm user can dismiss or go back to home without getting stuck. | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### 4.4 QR code — valid

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | Generate a valid join link and encode it as a QR code (Host UI or external generator). | ☐ | |
| 2 | Scan the QR with the test device (in-app scanner if available, or system camera → open in Player). | ☐ | |
| 3 | Confirm Player app opens and joins the correct session (cold or warm as applicable). | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### 4.5 QR code — invalid

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | Use a QR that does not contain a valid Club Blackout join link (wrong app, wrong URL, or garbage). | ☐ | |
| 2 | Scan with the test device. | ☐ | |
| 3 | Confirm no crash; app either ignores it or shows a clear “invalid”/error state. | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### Section 4 overall

| Check | Result |
|-------|--------|
| 4.1 Cold-start deep-link | ☐ PASS ☐ FAIL |
| 4.2 Warm-start deep-link | ☐ PASS ☐ FAIL |
| 4.3 Invalid/expired link | ☐ PASS ☐ FAIL |
| 4.4 QR valid | ☐ PASS ☐ FAIL |
| 4.5 QR invalid | ☐ PASS ☐ FAIL |

**Section 4 outcome:** ☐ PASS (all 5) ☐ FAIL (list sub-items): _________________

**Tester / date:** _________________

---

## Section 5) Host iOS email-link E2E

Requires: **physical iOS device**, Mail app, Host join link sent via email.

### 5.1 Host join link via email (iOS)

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | On a host machine or device, create a Host session and obtain the join link (e.g. “Invite players” / copy link). | ☐ | |
| 2 | Email that link to an address accessible on the iOS device (e.g. same Apple ID Mail). | ☐ | |
| 3 | On the **iOS device**, open the Mail app and open the email. | ☐ | |
| 4 | Tap the join link in the email body. | ☐ | |
| 5 | Confirm the Player app (or Host app, per design) launches and joins the correct session. | ☐ | |
| 6 | Complete any claim/join flow and confirm lobby/game state is correct. | ☐ | |

**Result: PASS / FAIL**  
**Evidence:** (screenshot IDs or file names)

---

### 5.2 (Optional) Host app on iOS — open link from Mail

If the Host app is also installed on iOS and should accept join or invite links:

| Step | Action | Pass? | Notes / evidence |
|------|--------|------|------------------|
| 1 | Send a Host-specific link (if any) via email to the iOS device. | ☐ | |
| 2 | Open Mail on iOS and tap the link. | ☐ | |
| 3 | Confirm the Host app opens and shows the expected screen (e.g. lobby or game). | ☐ | |

**Result: PASS / FAIL / N/A**  
**Evidence:** (screenshot IDs or file names)

---

### Section 5 overall

| Check | Result |
|-------|--------|
| 5.1 Player join via email link on iOS | ☐ PASS ☐ FAIL |
| 5.2 Host app via email link on iOS (if applicable) | ☐ PASS ☐ FAIL ☐ N/A |

**Section 5 outcome:** ☐ PASS ☐ FAIL (list sub-items): _________________

**Tester / date:** _________________

---

## After validation

1. Update [runbook-execution-2026-02-20.md](runbook-execution-2026-02-20.md): set Section 4 and Section 5 to **PASS** or **FAIL** and paste a one-line summary per section.
2. If you captured evidence, add a short “Evidence” line to each section in the runbook (e.g. “Screenshots: `evidence/section4-*.png`”).
3. Update “Current runbook execution state” and “Deployment posture” in the runbook based on outcomes.
