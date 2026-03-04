const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
  getDoc,
  collection,
  addDoc,
  serverTimestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'cb-reborn-rules-test';
let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: require('node:fs').readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'games/ABCD1'), {
      hostId: 'host_uid',
      phase: 'day',
      dayCount: 1,
      players: [],
    });

    await setDoc(doc(db, 'games/ABCD1/private_state/player_alpha'), {
      uid: 'player_uid',
      roleId: 'party_animal',
    });

    await setDoc(doc(db, 'games/ABCD1/private_state/player_bravo'), {
      uid: 'other_uid',
      roleId: 'dealer',
    });
  });
});

test('allows action create when auth user owns player id via private_state.uid', async () => {
  const db = testEnv.authenticatedContext('player_uid').firestore();

  await assertSucceeds(
    addDoc(collection(db, 'games/ABCD1/actions'), {
      type: 'interaction',
      stepId: 'day_vote',
      playerId: 'player_alpha',
      targetId: 'player_bravo',
      payload: {},
      timestamp: serverTimestamp(),
    }),
  );
});

test('rejects action create when auth user spoofs different player id', async () => {
  const db = testEnv.authenticatedContext('player_uid').firestore();

  await assertFails(
    addDoc(collection(db, 'games/ABCD1/actions'), {
      type: 'interaction',
      stepId: 'day_vote',
      playerId: 'player_bravo',
      targetId: 'player_alpha',
      payload: {},
      timestamp: serverTimestamp(),
    }),
  );
});

test('rejects chat create with unknown sender id', async () => {
  const db = testEnv.authenticatedContext('player_uid').firestore();

  await assertFails(
    addDoc(collection(db, 'games/ABCD1/chat'), {
      playerId: 'unknown',
      message: 'hello',
      timestamp: serverTimestamp(),
    }),
  );
});

test('allows private_state read for owning uid field', async () => {
  const db = testEnv.authenticatedContext('player_uid').firestore();

  await assertSucceeds(getDoc(doc(db, 'games/ABCD1/private_state/player_alpha')));
});

test('rejects private_state read for non-owner non-host', async () => {
  const db = testEnv.authenticatedContext('random_uid').firestore();

  await assertFails(getDoc(doc(db, 'games/ABCD1/private_state/player_alpha')));
});

test('host can read/write private_state', async () => {
  const db = testEnv.authenticatedContext('host_uid').firestore();

  await assertSucceeds(getDoc(doc(db, 'games/ABCD1/private_state/player_alpha')));
  await assertSucceeds(
    setDoc(
      doc(db, 'games/ABCD1/private_state/player_alpha'),
      { roleId: 'updated_role' },
      { merge: true },
    ),
  );

  const snap = await getDoc(doc(db, 'games/ABCD1/private_state/player_alpha'));
  assert.equal(snap.exists(), true);
});
