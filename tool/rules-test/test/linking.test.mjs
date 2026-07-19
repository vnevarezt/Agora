// Rules for the passphrase-free key model (phase 4c): the identity doc and
// the device-linking mailbox.
//
// The load-bearing test is "another signed-in user can neither read nor write
// the mailbox" — together with the payload travelling out of band, that is
// the whole security argument for linking.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'agora-linking-test',
    firestore: { rules: readFileSync(join(root, 'firestore.rules'), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const inMinutes = (n) => Timestamp.fromMillis(Date.now() + n * 60_000);
const mailbox = (over = {}) => ({
  createdAt: serverTimestamp(),
  expiresAt: inMinutes(5),
  ...over,
});
const box = { v: '1', epk: 'e', nonce: 'n', ct: 'c', mac: 'm' };

/** Rules-bypassed fixture: a mailbox as it exists after creation. */
async function plantMailbox(uid, sessionId, over = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${uid}/links/${sessionId}`), {
      createdAt: Timestamp.now(),
      expiresAt: inMinutes(5),
      ...over,
    });
  });
}

// ---------------------------------------------------------------------------
describe('users/{uid}: identity doc', () => {
  const identity = { pubKey: 'pk', keyUpdatedAt: serverTimestamp(), createdAt: serverTimestamp() };

  it('owner creates it with only the public key; others cannot read it', async () => {
    await assertSucceeds(setDoc(doc(db('ana'), 'users/ana'), identity));
    await assertSucceeds(getDoc(doc(db('ana'), 'users/ana')));
    await assertFails(getDoc(doc(db('bob'), 'users/ana')));
    await assertFails(getDoc(doc(anon(), 'users/ana')));
  });

  it('rejects a doc carrying the legacy passphrase envelope', async () => {
    await assertFails(setDoc(doc(db('ana'), 'users/ana'),
      { ...identity, wrappedPrivKey: 'legacy' }));
  });

  it('pubKey is frozen once published', async () => {
    await setDoc(doc(db('ana'), 'users/ana'), identity);
    await assertFails(updateDoc(doc(db('ana'), 'users/ana'), { pubKey: 'other' }));
    await assertSucceeds(
      updateDoc(doc(db('ana'), 'users/ana'), { keyUpdatedAt: serverTimestamp() }));
  });

  it('the migration may DROP wrappedPrivKey but never re-add it', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/ana'),
        { pubKey: 'pk', wrappedPrivKey: 'legacy', createdAt: Timestamp.now() });
    });
    // Rewriting without the envelope is the migration write.
    await assertSucceeds(setDoc(doc(db('ana'), 'users/ana'),
      { pubKey: 'pk', keyUpdatedAt: serverTimestamp(), createdAt: Timestamp.now() }));
    await assertFails(
      updateDoc(doc(db('ana'), 'users/ana'), { wrappedPrivKey: 'back' }));
  });

  it('owner may delete it (identity reset); nobody else may', async () => {
    await setDoc(doc(db('ana'), 'users/ana'), identity);
    await assertFails(deleteDoc(doc(db('bob'), 'users/ana')));
    await assertSucceeds(deleteDoc(doc(db('ana'), 'users/ana')));
  });
});

// ---------------------------------------------------------------------------
describe('users/{uid}/links: the device-linking mailbox', () => {
  it('owner creates an empty, short-lived mailbox', async () => {
    await assertSucceeds(
      setDoc(doc(db('ana'), 'users/ana/links/s1'), mailbox()));
  });

  it('THE security test: another account can neither read nor write it', async () => {
    await plantMailbox('ana', 's1');
    await assertFails(getDoc(doc(db('mallory'), 'users/ana/links/s1')));
    await assertFails(
      updateDoc(doc(db('mallory'), 'users/ana/links/s1'), { response: box }));
    await assertFails(
      setDoc(doc(db('mallory'), 'users/ana/links/s2'), mailbox()));
    await assertFails(getDoc(doc(anon(), 'users/ana/links/s1')));
  });

  it('rejects a client-chosen createdAt, extra fields, or a long life', async () => {
    await assertFails(setDoc(doc(db('ana'), 'users/ana/links/s1'),
      { createdAt: Timestamp.now(), expiresAt: inMinutes(5) }));
    await assertFails(setDoc(doc(db('ana'), 'users/ana/links/s1'),
      { ...mailbox(), response: box }));
    // A mailbox that would dangle for a day.
    await assertFails(setDoc(doc(db('ana'), 'users/ana/links/s1'),
      mailbox({ expiresAt: inMinutes(60 * 24) })));
  });

  it('the response can be written exactly once, and only before expiry', async () => {
    await plantMailbox('ana', 's1');
    await assertSucceeds(
      updateDoc(doc(db('ana'), 'users/ana/links/s1'), { response: box }));
    // A second write would let a stale device overwrite the answer.
    await assertFails(
      updateDoc(doc(db('ana'), 'users/ana/links/s1'), { response: box }));

    await plantMailbox('ana', 'expired', { expiresAt: inMinutes(-1) });
    await assertFails(
      updateDoc(doc(db('ana'), 'users/ana/links/expired'), { response: box }));
  });

  it('the response write may not touch anything else', async () => {
    await plantMailbox('ana', 's1');
    await assertFails(updateDoc(doc(db('ana'), 'users/ana/links/s1'),
      { response: box, expiresAt: inMinutes(60) }));
  });

  it('owner deletes the mailbox after consuming it', async () => {
    await plantMailbox('ana', 's1', { response: box });
    await assertSucceeds(deleteDoc(doc(db('ana'), 'users/ana/links/s1')));
  });
});
