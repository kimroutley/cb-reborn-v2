/**
 * Club Blackout Reborn - Cloud Functions
 * Sends Web Push notifications when game state or private state changes in Firestore.
 *
 * Setup:
 * 1. Generate VAPID keys: npx web-push generate-vapid-keys
 * 2. Set config: firebase functions:config:set vapid.private_key="..." vapid.public_key="..."
 * 3. Put the public key in apps/player/lib/services/push_subscription_register.dart (vapidPublicKeyBase64)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const webpush = require('web-push');

admin.initializeApp();

function getVapidKeys() {
  const privateKey = functions.config().vapid?.private_key;
  const publicKey = functions.config().vapid?.public_key;
  if (!privateKey || !publicKey) {
    console.warn('VAPID keys not set. Run: firebase functions:config:set vapid.private_key="..." vapid.public_key="..."');
    return null;
  }
  return { publicKey, privateKey };
}

/**
 * Send a Web Push notification to a subscription doc from Firestore.
 */
async function sendToSubscription(subscriptionDoc, payload) {
  const endpoint = subscriptionDoc.endpoint;
  const keys = subscriptionDoc.keys;
  if (!endpoint || !keys || !keys.p256dh || !keys.auth) return;
  const vapidKeys = getVapidKeys();
  if (!vapidKeys) return;
  webpush.setVapidDetails(
    'mailto:club-blackout@example.com',
    vapidKeys.publicKey,
    vapidKeys.privateKey
  );
  try {
    await webpush.sendNotification(
      {
        endpoint: subscriptionDoc.endpoint,
        keys: {
          p256dh: subscriptionDoc.keys.p256dh,
          auth: subscriptionDoc.keys.auth,
        },
      },
      JSON.stringify(payload),
      { TTL: 3600 }
    );
  } catch (e) {
    if (e.statusCode === 410 || e.statusCode === 404) {
      // Subscription expired or invalid - could delete the doc
    }
    console.warn('Web Push failed:', e.message);
  }
}

/**
 * Get push subscriptions for the given player IDs and send one notification per subscription.
 */
async function sendToPlayers(db, joinCode, playerIds, payload) {
  if (playerIds.length === 0) return;
  const vapidKeys = getVapidKeys();
  if (!vapidKeys) return;
  const ref = db.collection('games').doc(joinCode).collection('push_subscriptions');
  for (const playerId of playerIds) {
    const doc = await ref.doc(playerId).get();
    if (!doc.exists) continue;
    const data = doc.data();
    await sendToSubscription(data, payload);
  }
}

/**
 * On game document update: detect phase change, rematch, new bulletin and notify relevant players.
 */
exports.onGameUpdated = functions.firestore
  .document('games/{joinCode}')
  .onUpdate(async (change, context) => {
    const joinCode = context.params.joinCode;
    const before = change.before.data();
    const after = change.after.data();
    const db = admin.firestore();

    const phaseBefore = before.phase || 'lobby';
    const phaseAfter = after.phase || 'lobby';
    const rematchBefore = !!before.rematchOffered;
    const rematchAfter = !!after.rematchOffered;
    const players = after.players || [];
    const playerIds = players.map((p) => p.id).filter(Boolean);

    const notifications = [];

    // Phase -> setup or night: game started
    if (phaseBefore !== phaseAfter && (phaseAfter === 'setup' || phaseAfter === 'night')) {
      notifications.push({
        playerIds,
        title: 'Club Blackout',
        body: 'The game is starting! Open the app to see your role.',
      });
    }

    // Phase -> day
    if (phaseBefore !== phaseAfter && phaseAfter === 'day') {
      const living = (players.filter((p) => p.isAlive !== false)).map((p) => p.id);
      notifications.push({
        playerIds: living,
        title: 'Club Blackout',
        body: 'Day phase — time to discuss and vote.',
      });
    }

    // Phase -> night
    if (phaseBefore !== phaseAfter && phaseAfter === 'night') {
      notifications.push({
        playerIds,
        title: 'Club Blackout',
        body: 'Night phase — check the app for your action.',
      });
    }

    // Rematch offered
    if (!rematchBefore && rematchAfter) {
      notifications.push({
        playerIds,
        title: 'Club Blackout',
        body: 'Rematch! The host started a new game. Open the app to rejoin.',
      });
    }

    // New non-host-only bulletin (simplified: compare bulletinBoard length)
    const bulletinBefore = (before.bulletinBoard || []).filter((b) => !b.isHostOnly);
    const bulletinAfter = (after.bulletinBoard || []).filter((b) => !b.isHostOnly);
    if (bulletinAfter.length > bulletinBefore.length && bulletinAfter.length > 0) {
      const last = bulletinAfter[bulletinAfter.length - 1];
      notifications.push({
        playerIds,
        title: last.title || 'Club Blackout',
        body: (last.content || last.floatContent || '').substring(0, 100) || 'New message in the game.',
      });
    }

    for (const n of notifications) {
      await sendToPlayers(db, joinCode, n.playerIds, { title: n.title, body: n.body });
    }
  });

/**
 * On private state update: role assigned -> notify that player.
 */
exports.onPrivateStateUpdated = functions.firestore
  .document('games/{joinCode}/private_state/{playerId}')
  .onUpdate(async (change, context) => {
    const joinCode = context.params.joinCode;
    const playerId = context.params.playerId;
    const before = change.before.data();
    const after = change.after.data();
    const roleBefore = before.roleId || '';
    const roleAfter = after.roleId || '';
    if (roleBefore === roleAfter || !roleAfter || roleAfter === 'unassigned') return;
    const db = admin.firestore();
    await sendToPlayers(db, joinCode, [playerId], {
      title: 'Club Blackout',
      body: 'Your role is ready. Open the app to confirm and see your character.',
    });
  });
