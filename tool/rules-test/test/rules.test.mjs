// Firestore security-rules tests for phase 4b (firestore.rules).
// Runs against the emulator: firebase emulators:exec --only firestore \
//   'npm --prefix tool/rules-test test'
//
// The redemption suite is the load-bearing one: single-use invites without
// Cloud Functions hinge on exists()/existsAfter() batch semantics.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'agora-rules-test',
    firestore: { rules: readFileSync(join(root, 'firestore.rules'), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const CAPS_ADMIN = { admin: true, people: true, editTypes: ['*'] };
const CAPS_VIEW = { admin: false, people: false, editTypes: [] };

const memberDoc = (uid, caps, extra = {}) => ({
  uid,
  pubKey: 'pk-' + uid,
  capabilities: caps,
  wrappedCcks: { 1: { v: '1', epk: 'e', nonce: 'n', ct: 'c', mac: 'm' } },
  inviteId: null,
  addedBy: uid,
  status: 'active',
  createdAt: serverTimestamp(),
  ...extra,
});

/** Founder bootstrap batch: congregation meta + own admin member doc. */
async function found(uid, cid) {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, `congregations/${cid}`), {
    createdBy: uid,
    createdAt: serverTimestamp(),
    keyVersion: 1,
  });
  batch.set(doc(d, `congregations/${cid}/members/${uid}`), memberDoc(uid, CAPS_ADMIN));
  await batch.commit();
}

/** Admin plants a member doc for another uid (rules-bypassed test fixture). */
async function plantMember(cid, uid, caps) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), `congregations/${cid}/members/${uid}`),
      memberDoc(uid, caps),
    );
  });
}

async function plantInvite(cid, tokenId, caps, { expired = false, createdBy = 'admin' } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `congregations/${cid}/invites/${tokenId}`), {
      capabilities: caps,
      wrappedKeyring: { v: '1', nonce: 'n', ct: 'c', mac: 'm' },
      createdBy,
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromMillis(Date.now() + (expired ? -1 : 1) * 86400_000),
    });
  });
}

const item = (over = {}) => ({
  entity: 'person',
  programTypeId: null,
  hlc: '0000000000000000001-0000-dev',
  srcDevice: 'dev',
  keyVersion: 1,
  blob: 'AAAA',
  serverTs: serverTimestamp(),
  ...over,
});

/** Redemption batch: create own member doc + delete the invite. */
function redeemBatch(d, cid, uid, tokenId, caps, { deleteInvite = true } = {}) {
  const batch = writeBatch(d);
  batch.set(doc(d, `congregations/${cid}/members/${uid}`), memberDoc(uid, caps, {
    inviteId: tokenId,
    addedBy: 'admin',
  }));
  if (deleteInvite) batch.delete(doc(d, `congregations/${cid}/invites/${tokenId}`));
  return batch.commit();
}

// ---------------------------------------------------------------------------
describe('invite redemption (the linchpin: getAfter/existsAfter)', () => {
  it('redeems with the [create member, delete invite] batch', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW);
    await assertSucceeds(redeemBatch(db('bob'), 'c1', 'bob', 'tok1', CAPS_VIEW));
    // Invite is gone; member exists.
    await env.withSecurityRulesDisabled(async (ctx) => {
      const inv = await getDoc(doc(ctx.firestore(), 'congregations/c1/invites/tok1'));
      assert.equal(inv.exists(), false);
      const mem = await getDoc(doc(ctx.firestore(), 'congregations/c1/members/bob'));
      assert.equal(mem.exists(), true);
    });
  });

  it('rejects redemption that does NOT delete the invite (reusable otherwise)', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW);
    await assertFails(
      redeemBatch(db('bob'), 'c1', 'bob', 'tok1', CAPS_VIEW, { deleteInvite: false }),
    );
  });

  it('rejects a second redemption of the same token', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW);
    await assertSucceeds(redeemBatch(db('bob'), 'c1', 'bob', 'tok1', CAPS_VIEW));
    await assertFails(redeemBatch(db('eve'), 'c1', 'eve', 'tok1', CAPS_VIEW));
  });

  it('rejects expired invites', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW, { expired: true });
    await assertFails(redeemBatch(db('bob'), 'c1', 'bob', 'tok1', CAPS_VIEW));
  });

  it('rejects capability escalation (caps must copy the invite verbatim)', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW);
    await assertFails(redeemBatch(db('bob'), 'c1', 'bob', 'tok1', CAPS_ADMIN));
  });

  it('rejects creating a member doc for someone else', async () => {
    await found('admin', 'c1');
    await plantInvite('c1', 'tok1', CAPS_VIEW);
    await assertFails(redeemBatch(db('mallory'), 'c1', 'bob', 'tok1', CAPS_VIEW));
  });
});

// ---------------------------------------------------------------------------
describe('congregation bootstrap', () => {
  it('founder batch (congregation + admin member) succeeds', async () => {
    await assertSucceeds(found('ana', 'c1'));
  });

  it('member doc without the congregation write fails', async () => {
    const d = db('ana');
    await assertFails(
      setDoc(doc(d, 'congregations/c9/members/ana'), memberDoc('ana', CAPS_ADMIN)),
    );
  });

  it('congregation with keyVersion != 1 or foreign createdBy fails', async () => {
    const d = db('ana');
    await assertFails(setDoc(doc(d, 'congregations/c1'), {
      createdBy: 'ana', createdAt: serverTimestamp(), keyVersion: 2,
    }));
    await assertFails(setDoc(doc(d, 'congregations/c1'), {
      createdBy: 'otro', createdAt: serverTimestamp(), keyVersion: 1,
    }));
  });

  it('only admins bump keyVersion, and only upward + nothing else', async () => {
    await found('ana', 'c1');
    await plantMember('c1', 'bob', CAPS_VIEW);
    await assertFails(updateDoc(doc(db('bob'), 'congregations/c1'), { keyVersion: 2 }));
    await assertFails(updateDoc(doc(db('ana'), 'congregations/c1'), { keyVersion: 0 }));
    await assertFails(updateDoc(doc(db('ana'), 'congregations/c1'), { keyVersion: 2, createdBy: 'x' }));
    await assertSucceeds(updateDoc(doc(db('ana'), 'congregations/c1'), { keyVersion: 2 }));
  });
});

// ---------------------------------------------------------------------------
describe('items: capability matrix per entity kind', () => {
  // One doc id PER entity kind: the kind-immutability rule (correctly)
  // rejects rewriting an existing doc as a different entity.
  const write = (uid, over) =>
    setDoc(doc(db(uid), `congregations/c1/items/x-${over.entity}`), item(over));

  beforeEach(async () => {
    await found('admin', 'c1');
    await plantMember('c1', 'viewer', CAPS_VIEW);
    await plantMember('c1', 'secretary', { admin: false, people: true, editTypes: [] });
    await plantMember('c1', 'vmc-editor', { admin: false, people: false, editTypes: ['mwb-s140'] });
  });

  it('people capability gates person/personAbsence', async () => {
    await assertSucceeds(write('secretary', { entity: 'person' }));
    await assertSucceeds(write('admin', { entity: 'personAbsence' }));
    await assertFails(write('viewer', { entity: 'person' }));
    await assertFails(write('vmc-editor', { entity: 'person' }));
  });

  it('edit:<type> gates program/assignment by clear programTypeId', async () => {
    await assertSucceeds(write('vmc-editor', { entity: 'program', programTypeId: 'mwb-s140' }));
    await assertSucceeds(write('admin', { entity: 'assignment', programTypeId: 'otro-tipo' }));
    await assertFails(write('vmc-editor', { entity: 'program', programTypeId: 'otro-tipo' }));
    await assertFails(write('secretary', { entity: 'program', programTypeId: 'mwb-s140' }));
    // program/assignment REQUIRE a clear programTypeId.
    await assertFails(write('vmc-editor', { entity: 'program', programTypeId: null }));
  });

  it('project needs any edit capability; congregation needs admin', async () => {
    await assertSucceeds(write('vmc-editor', { entity: 'project' }));
    await assertFails(write('secretary', { entity: 'project' }));
    await assertSucceeds(write('admin', { entity: 'congregation' }));
    await assertFails(write('vmc-editor', { entity: 'congregation' }));
  });

  it('viewer reads but never writes; non-members see nothing', async () => {
    await write('admin', { entity: 'congregation' });
    const path = 'congregations/c1/items/x-congregation';
    await assertSucceeds(getDoc(doc(db('viewer'), path)));
    await assertFails(write('viewer', { entity: 'project' }));
    await assertFails(getDoc(doc(db('stranger'), path)));
    await assertFails(getDoc(doc(anon(), path)));
  });

  it('the pull query (orderBy serverTs, where >) is provable for members', async () => {
    await write('admin', { entity: 'congregation' });
    // Updating the SAME doc with the SAME kind stays allowed (LWW re-push).
    await assertSucceeds(write('admin', { entity: 'congregation' }));
    const q = query(
      collection(db('viewer'), 'congregations/c1/items'),
      where('serverTs', '>', Timestamp.fromMillis(0)),
      orderBy('serverTs'),
    );
    await assertSucceeds(getDocs(q));
    await assertFails(getDocs(query(
      collection(db('stranger'), 'congregations/c1/items'),
      orderBy('serverTs'),
    )));
  });

  it('forces serverTimestamp(), exact shape, and kind immutability', async () => {
    // A client-chosen serverTs is rejected.
    await assertFails(write('admin', { entity: 'person', serverTs: Timestamp.now() }));
    // Extra fields are rejected.
    await assertFails(write('admin', { entity: 'person', extra: 1 }));
    // Deletes are rejected (tombstones live inside blobs).
    await write('admin', { entity: 'person' });
    await assertFails(deleteDoc(doc(db('admin'), 'congregations/c1/items/x-person')));
    // Rewriting the kind (person → program) is rejected even for admins.
    await assertFails(setDoc(doc(db('admin'), 'congregations/c1/items/x-person'),
      item({ entity: 'program', programTypeId: 'mwb-s140' })));
  });
});

// ---------------------------------------------------------------------------
describe('members and users docs', () => {
  beforeEach(async () => {
    await found('admin', 'c1');
    await plantMember('c1', 'bob', CAPS_VIEW);
  });

  it('collection-group membership query works for own uid only', async () => {
    await assertSucceeds(getDocs(query(
      collectionGroup(db('bob'), 'members'),
      where('uid', '==', 'bob'),
    )));
    await assertFails(getDocs(query(
      collectionGroup(db('bob'), 'members'),
      where('uid', '==', 'admin'),
    )));
  });

  it('a member can direct-get their OWN member doc (CCK recovery path)', async () => {
    // cck_service.refresh() reads this to recover the wrapped CCK.
    await assertSucceeds(getDoc(doc(db('bob'), 'congregations/c1/members/bob')));
    await assertSucceeds(getDoc(doc(db('admin'), 'congregations/c1/members/admin')));
  });

  it('reading a member doc you have no claim to is denied (→ client null)', async () => {
    // A local-only / not-joined congregation: the member doc does not exist,
    // and a non-member reading it is denied. FirestoreKeyDocs.readMemberDoc
    // must treat this permission-denied as "not syncable", not a crash.
    await assertFails(
        getDoc(doc(db('stranger'), 'congregations/c1/members/stranger')));
    await assertFails(
        getDoc(doc(db('stranger'), 'congregations/does-not-exist/members/stranger')));
  });

  it('admin updates capabilities; wrappedCcks is append-only; pubKey frozen', async () => {
    const ref = doc(db('admin'), 'congregations/c1/members/bob');
    await assertSucceeds(updateDoc(ref, {
      capabilities: { admin: false, people: true, editTypes: [] },
      'wrappedCcks.2': { v: '1', epk: 'e', nonce: 'n', ct: 'c', mac: 'm' },
    }));
    await assertFails(updateDoc(ref, { 'wrappedCcks.1': deleteField() }));
    await assertFails(updateDoc(ref, { pubKey: 'evil' }));
    await assertFails(updateDoc(doc(db('bob'), 'congregations/c1/members/bob'), {
      capabilities: CAPS_ADMIN,
    }));
  });

  it('revocation: admin deletes; members may leave; strangers may not', async () => {
    await assertFails(deleteDoc(doc(db('stranger'), 'congregations/c1/members/bob')));
    await assertSucceeds(deleteDoc(doc(db('bob'), 'congregations/c1/members/bob')));
    await plantMember('c1', 'bob', CAPS_VIEW);
    await assertSucceeds(deleteDoc(doc(db('admin'), 'congregations/c1/members/bob')));
  });

  it('meta/activity heartbeat: writers bump, viewers read-only, strangers nothing', async () => {
    const bump = (uid) => setDoc(
      doc(db(uid), 'congregations/c1/meta/activity'),
      { scopes: { p1: serverTimestamp() }, srcDevice: 'dev-' + uid },
      { merge: true },
    );
    await plantMember('c1', 'editor', { admin: false, people: false, editTypes: ['mwb-s140'] });
    await assertSucceeds(bump('admin'));
    await assertSucceeds(bump('editor'));
    await assertFails(bump('bob'));       // viewer: read-only caps
    await assertFails(bump('stranger'));  // not a member
    await assertSucceeds(getDoc(doc(db('bob'), 'congregations/c1/meta/activity')));
    await assertFails(getDoc(doc(db('stranger'), 'congregations/c1/meta/activity')));
    // Extra fields are rejected.
    await assertFails(setDoc(doc(db('admin'), 'congregations/c1/meta/activity'),
      { scopes: {}, srcDevice: 'd', extra: 1 }));
  });

  it('users/{uid} is owner-only', async () => {
    await assertSucceeds(setDoc(doc(db('ana'), 'users/ana'), { pubKey: 'p', wrappedPrivKey: 'w' }));
    await assertFails(getDoc(doc(db('bob'), 'users/ana')));
    await assertFails(setDoc(doc(db('bob'), 'users/ana'), { pubKey: 'x' }));
  });

  it('invites: get by token for anyone signed in, list only for admins', async () => {
    await plantInvite('c1', 'tok9', CAPS_VIEW);
    await assertSucceeds(getDoc(doc(db('somebody'), 'congregations/c1/invites/tok9')));
    await assertFails(getDoc(doc(anon(), 'congregations/c1/invites/tok9')));
    await assertSucceeds(getDocs(collection(db('admin'), 'congregations/c1/invites')));
    await assertFails(getDocs(collection(db('bob'), 'congregations/c1/invites')));
  });
});
