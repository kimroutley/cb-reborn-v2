const test = require('node:test');
const assert = require('node:assert/strict');

const { _internal } = require('../index');
const { detectPushableEvents } = _internal;

const PLAYERS = [
  { id: 'p1', isAlive: true, roleId: 'dealer' },
  { id: 'p2', isAlive: true, roleId: 'civilian' },
];

function game(phase, extra = {}) {
  return { phase, players: PLAYERS, bulletinBoard: [], ...extra };
}

// ── Role assigned on phase → setup ──────────────────────────────────────────

test('role-assigned event emitted when entering setup phase', () => {
  const events = detectPushableEvents(game('lobby'), game('setup'));
  assert.ok(events.length >= 2);
  assert.ok(events.every((e) => e.data.tag === 'role-assigned'));
  assert.ok(events.some((e) => e.playerId === 'p1'));
  assert.ok(events.some((e) => e.playerId === 'p2'));
});

test('no role-assigned events when not transitioning to setup', () => {
  const events = detectPushableEvents(game('night'), game('day'));
  assert.ok(!events.some((e) => e.data.tag === 'role-assigned'));
});

// ── Night phase ──────────────────────────────────────────────────────────────

test('night-start events for alive players', () => {
  const events = detectPushableEvents(game('day'), game('night'));
  assert.equal(events.filter((e) => e.data.tag === 'night-start').length, 2);
});

// ── Day/morning phase ────────────────────────────────────────────────────────

test('day-start events when transitioning from night to day', () => {
  const events = detectPushableEvents(game('night'), game('day'));
  assert.ok(events.some((e) => e.data.tag === 'day-start'));
});

test('day-start events when transitioning from night to morning', () => {
  const events = detectPushableEvents(game('night'), game('morning'));
  assert.ok(events.some((e) => e.data.tag === 'day-start'));
});

// ── Vote phase ───────────────────────────────────────────────────────────────

test('vote-start events for alive players', () => {
  const events = detectPushableEvents(game('day'), game('vote'));
  assert.equal(events.filter((e) => e.data.tag === 'vote-start').length, 2);
});

// ── Game over ────────────────────────────────────────────────────────────────

test('game-over events for all players', () => {
  const events = detectPushableEvents(game('vote'), game('endGame'));
  assert.equal(events.filter((e) => e.data.tag === 'game-over').length, 2);
});

// ── Rematch offered ──────────────────────────────────────────────────────────

test('rematch-offered event when rematchOffered flips to true', () => {
  const events = detectPushableEvents(
    game('endGame', { rematchOffered: false }),
    game('endGame', { rematchOffered: true }),
  );
  assert.equal(events.filter((e) => e.data.tag === 'rematch-offered').length, 2);
  assert.ok(events.some((e) => e.playerId === 'p1'));
  assert.ok(events.some((e) => e.playerId === 'p2'));
});

test('no rematch events when rematchOffered was already true', () => {
  const events = detectPushableEvents(
    game('endGame', { rematchOffered: true }),
    game('endGame', { rematchOffered: true }),
  );
  assert.ok(!events.some((e) => e.data.tag === 'rematch-offered'));
});

// ── Private message ──────────────────────────────────────────────────────────

test('private-message event for bulletin entry with targetPlayerId', () => {
  const before = { ...game('night'), bulletinBoard: [] };
  const after = {
    ...game('night'),
    bulletinBoard: [
      { type: 'privateMessage', targetPlayerId: 'p1', message: 'Hello' },
    ],
  };
  const events = detectPushableEvents(before, after);
  assert.equal(events.filter((e) => e.data.tag === 'private-message').length, 1);
  assert.equal(events[0].playerId, 'p1');
});

test('no events when before or after is null', () => {
  assert.deepEqual(detectPushableEvents(null, game('night')), []);
  assert.deepEqual(detectPushableEvents(game('night'), null), []);
});
