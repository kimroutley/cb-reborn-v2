# Club Blackout Reborn – Cloud Functions

Sends Web Push notifications when the host updates game state or player private state in Firestore.

## Setup

1. **Install dependencies**
   ```bash
   cd functions && npm install
   ```

2. **Generate VAPID keys**
   ```bash
   npx web-push generate-vapid-keys
   ```
   Copy the **public key** and **private key**.

3. **Configure Firebase**
   ```bash
   firebase functions:config:set vapid.public_key="YOUR_PUBLIC_KEY" vapid.private_key="YOUR_PRIVATE_KEY"
   ```

4. **Set the public key in the player app**  
   In `apps/player/lib/services/push_subscription_register.dart`, set:
   ```dart
   const String vapidPublicKeyBase64 = 'YOUR_PUBLIC_KEY';
   ```
   (Use the same public key string from step 2.)

5. **Deploy**
   ```bash
   firebase deploy --only functions
   ```

## Triggers

- **onGameUpdated**: `games/{joinCode}`  
  Sends push when: game starts (phase → setup/night), phase → day, phase → night, rematch offered, new public bulletin.

- **onPrivateStateUpdated**: `games/{joinCode}/private_state/{playerId}`  
  Sends push when a player’s role is assigned (roleId set and not unassigned).

## Events covered

See `docs/COMMUNICATION_AND_PUSH.md` for the full event catalog and implementation status.
