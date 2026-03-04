const test = require('node:test');
const assert = require('node:assert/strict');

const { _internal } = require('../index');

const {
  isGameStaleForCleanup,
  buildCleanupTelemetry,
  ENDGAME_STALE_MS,
  GENERAL_STALE_MS,
} = _internal;

test('endGame entries become stale after endgame threshold', () => {
  const now = 1_700_000_000_000;
  const stale = {
    phase: 'endGame',
    updatedAt: now - ENDGAME_STALE_MS - 1,
  };
  const fresh = {
    phase: 'endGame',
    updatedAt: now - ENDGAME_STALE_MS + 1,
  };

  assert.equal(isGameStaleForCleanup(stale, now), true);
  assert.equal(isGameStaleForCleanup(fresh, now), false);
});

test('non-endGame entries use general stale threshold', () => {
  const now = 1_700_000_000_000;
  const stale = {
    phase: 'day',
    updatedAt: now - GENERAL_STALE_MS - 1,
  };
  const fresh = {
    phase: 'lobby',
    updatedAt: now - GENERAL_STALE_MS + 1,
  };

  assert.equal(isGameStaleForCleanup(stale, now), true);
  assert.equal(isGameStaleForCleanup(fresh, now), false);
});

test('invalid updatedAt values are never deleted by stale detector', () => {
  const now = 1_700_000_000_000;

  assert.equal(isGameStaleForCleanup({ phase: 'endGame' }, now), false);
  assert.equal(isGameStaleForCleanup({ phase: 'endGame', updatedAt: 0 }, now), false);
  assert.equal(isGameStaleForCleanup({ phase: 'endGame', updatedAt: 'bad' }, now), false);
  assert.equal(isGameStaleForCleanup({ phase: 'endGame', updatedAt: now + 1000 }, now), false);
});

test('cleanup telemetry payload includes computed run timestamp and counters', () => {
  const runAtMs = 1_700_000_000_000;
  const telemetry = buildCleanupTelemetry({
    scanned: 12,
    staleCandidates: 5,
    deleted: 4,
    failed: 1,
    durationMs: 987,
    runAtMs,
  });

  assert.deepEqual(telemetry, {
    scanned: 12,
    staleCandidates: 5,
    deleted: 4,
    failed: 1,
    durationMs: 987,
    runAt: new Date(runAtMs).toISOString(),
  });
});
