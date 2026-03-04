const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const webPush = require("web-push");

initializeApp();
const db = getFirestore();

// ─── VAPID configuration ───────────────────────────────────────────────────
// Set these via: firebase functions:config:set vapid.public="..." vapid.private="..." vapid.subject="mailto:..."
// Or use environment variables: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY || "";
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY || "";
const VAPID_SUBJECT = process.env.VAPID_SUBJECT || "mailto:admin@clubblackout.com";

if (VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) {
  webPush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
}

// ─── Push notification sender ──────────────────────────────────────────────

async function sendPushToPlayer(gameCode, playerId, payload) {
  if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) return;

  try {
    const doc = await db
      .collection("games")
      .doc(gameCode)
      .collection("private_state")
      .doc(playerId)
      .get();

    const sub = doc.data()?.pushSubscription;
    if (!sub?.endpoint) return;

    await webPush.sendNotification(sub, JSON.stringify(payload));
  } catch (err) {
    if (err.statusCode === 410 || err.statusCode === 404) {
      // Subscription expired — remove it.
      await db
        .collection("games")
        .doc(gameCode)
        .collection("private_state")
        .doc(playerId)
        .update({ pushSubscription: null });
    }
    console.warn(`Push to ${playerId} failed:`, err.message || err);
  }
}

async function sendPushToAllPlayers(gameCode, players, payload) {
  const promises = players.map((p) => sendPushToPlayer(gameCode, p.id, payload));
  await Promise.allSettled(promises);
}

// ─── Game-state change listener ────────────────────────────────────────────

function detectPushableEvents(before, after) {
  const events = [];
  if (!before || !after) return events;

  const prevPhase = before.phase;
  const nextPhase = after.phase;
  const players = after.players || [];

  // Role assignment (phase changed to setup, or roles newly present)
  // Check if phase entered setup OR if any player got a role for the first time
  const phaseEnteredSetup = prevPhase !== "setup" && nextPhase === "setup";
  
  for (const p of players) {
    const oldP = before.players?.find(op => op.id === p.id);
    const hadRole = oldP && oldP.roleId && oldP.roleId !== 'unassigned' && oldP.roleId !== 'hidden'; // 'hidden' means already assigned in public
    // Note: if roleId was 'hidden' before, they already had a role.
    // If roleId becomes 'hidden' (or a real ID if endGame), and they didn't have one, it's new.
    
    // In public doc, roleId is 'hidden' when assigned.
    // So transition: unassigned/null -> 'hidden' = Assigned.
    
    const hasRole = p.roleId && p.roleId !== 'unassigned';
    // const hadRoleSimple = oldP && oldP.roleId && oldP.roleId !== 'unassigned';
    
    // We want to trigger if:
    // 1. Phase entered setup (and they have a role) - bulk notify
    // 2. OR they didn't have a role before, and now they do.
    
    const isNewAssignment = hasRole && (!oldP || !oldP.roleId || oldP.roleId === 'unassigned');
    
    if (phaseEnteredSetup && hasRole || isNewAssignment) {
        // Dedup: if phaseEnteredSetup AND isNewAssignment, don't double add?
        // logic below pushes to events list.
        
        // We need to avoid duplicates in 'events' list for same player/tag.
        // But here we are iterating players.
        
        events.push({
          playerId: p.id,
          notification: {
            title: "Identity Assigned",
            body: "Your role has been assigned. Open the app to acknowledge.",
          },
          data: { tag: "role-assigned", playerId: p.id },
        });
    }
  }

  // Night phase started
  if (prevPhase !== "night" && nextPhase === "night") {
    for (const p of players) {
      if (p.isAlive) {
        events.push({
          playerId: p.id,
          notification: {
            title: "Night Falls",
            body: "The night phase has begun. Check if you have an action.",
          },
          data: { tag: "night-start" },
        });
      }
    }
  }

  // Day phase started (morning/vote)
  if (prevPhase === "night" && (nextPhase === "day" || nextPhase === "morning")) {
    for (const p of players) {
      if (p.isAlive) {
        events.push({
          playerId: p.id,
          notification: {
            title: "Dawn Breaks",
            body: "The morning report is in. Check what happened overnight.",
          },
          data: { tag: "day-start" },
        });
      }
    }
  }

  // Vote phase
  if (prevPhase !== "vote" && nextPhase === "vote") {
    for (const p of players) {
      if (p.isAlive) {
        events.push({
          playerId: p.id,
          notification: {
            title: "Time to Vote",
            body: "Cast your vote before time runs out!",
          },
          data: { tag: "vote-start" },
        });
      }
    }
  }

  // Game over
  if (prevPhase !== "endGame" && nextPhase === "endGame") {
    for (const p of players) {
      events.push({
        playerId: p.id,
        notification: {
          title: "Game Over",
          body: "The game has ended. Check the final results!",
        },
        data: { tag: "game-over" },
      });
    }
  }

  // Rematch offered
  if (!before.rematchOffered && after.rematchOffered) {
    for (const p of players) {
      events.push({
        playerId: p.id,
        notification: {
          title: "Rematch Time!",
          body: "The host is offering a rematch. Tap to rejoin!",
        },
        data: { tag: "rematch-offered" },
      });
    }
  }

  // New private messages (check bulletin for new entries targeting specific players)
  const prevBulletin = before.bulletinBoard || [];
  const nextBulletin = after.bulletinBoard || [];
  if (nextBulletin.length > prevBulletin.length) {
    const newEntries = nextBulletin.slice(prevBulletin.length);
    for (const entry of newEntries) {
      if (entry.type === "privateMessage" && entry.targetPlayerId) {
        events.push({
          playerId: entry.targetPlayerId,
          notification: {
            title: "Private Message",
            body: entry.message || "You have a new private message.",
          },
          data: { tag: "private-message" },
        });
      }
    }
  }

  return events;
}

exports.onGameStateChange = onDocumentWritten(
  "games/{gameCode}",
  async (event) => {
    const gameCode = event.params.gameCode;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    const pushEvents = detectPushableEvents(before, after);
    if (pushEvents.length === 0) return;

    const promises = pushEvents.map((evt) =>
      sendPushToPlayer(gameCode, evt.playerId, {
        notification: evt.notification,
        data: evt.data,
      })
    );
    await Promise.allSettled(promises);
  }
);

// ─── Stale game cleanup (scheduled) ───────────────────────────────────────

const ENDGAME_STALE_MS = 2 * 60 * 60 * 1000; // 2 hours
const GENERAL_STALE_MS = 24 * 60 * 60 * 1000; // 24 hours

function isGameStaleForCleanup(data, now) {
  const updated = data?.updatedAt;
  if (!updated || typeof updated !== "number" || updated <= 0 || updated > now) {
    return false;
  }
  const threshold =
    data.phase === "endGame" ? ENDGAME_STALE_MS : GENERAL_STALE_MS;
  return now - updated > threshold;
}

function buildCleanupTelemetry({
  scanned,
  staleCandidates,
  deleted,
  failed,
  durationMs,
  runAtMs,
}) {
  return {
    scanned,
    staleCandidates,
    deleted,
    failed,
    durationMs,
    runAt: new Date(runAtMs).toISOString(),
  };
}

exports.cleanupStaleGames = onSchedule("every 6 hours", async () => {
  const runAtMs = Date.now();
  const snapshot = await db.collection("games").get();
  let scanned = 0;
  let staleCandidates = 0;
  let deleted = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    scanned++;
    const data = doc.data();
    if (!isGameStaleForCleanup(data, runAtMs)) continue;
    staleCandidates++;
    try {
      // Delete subcollections first
      const subs = ["joins", "actions", "private_state"];
      for (const sub of subs) {
        const subDocs = await doc.ref.collection(sub).get();
        const batch = db.batch();
        for (const subDoc of subDocs.docs) {
          batch.delete(subDoc.ref);
        }
        await batch.commit();
      }
      await doc.ref.delete();
      deleted++;
    } catch (err) {
      failed++;
      console.error(`Failed to delete stale game ${doc.id}:`, err);
    }
  }

  const durationMs = Date.now() - runAtMs;
  const telemetry = buildCleanupTelemetry({
    scanned,
    staleCandidates,
    deleted,
    failed,
    durationMs,
    runAtMs,
  });
  console.log("Cleanup telemetry:", telemetry);
});

// Expose internals for unit tests
exports._internal = {
  isGameStaleForCleanup,
  buildCleanupTelemetry,
  ENDGAME_STALE_MS,
  GENERAL_STALE_MS,
  detectPushableEvents,
  sendPushToPlayer,
};
