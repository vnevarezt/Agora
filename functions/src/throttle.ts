import { createHash } from 'node:crypto';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const WINDOW_MS = 60 * 60 * 1000;
const MAX_PER_WINDOW = 5;
const MIN_GAP_MS = 60 * 1000;

/**
 * Nothing in front of these callables proves the caller is a person: the reset
 * one cannot require auth, since the whole point is that the user is locked
 * out. Without a limit, one script turns an inbox into a mailbomb and every
 * message is billed to the project.
 *
 * Keys are hashed because the collection would otherwise become a plaintext
 * list of every address that has ever asked for a reset — a worse thing to leak
 * than the rate state it exists to hold.
 */
export async function allow(scope: string, subject: string): Promise<boolean> {
  const key = createHash('sha256').update(`${scope}:${subject}`).digest('hex');
  const ref = getFirestore().collection('mailThrottle').doc(key);

  return getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();

    if (snap.exists) {
      const data = snap.data() ?? {};
      const start = (data.windowStart as Timestamp | undefined)?.toMillis() ?? 0;
      const last = (data.lastSent as Timestamp | undefined)?.toMillis() ?? 0;
      const count = (data.count as number | undefined) ?? 0;

      if (now - last < MIN_GAP_MS) return false;
      if (now - start < WINDOW_MS && count >= MAX_PER_WINDOW) return false;

      const fresh = now - start >= WINDOW_MS;
      tx.set(ref, {
        windowStart: fresh ? Timestamp.fromMillis(now) : Timestamp.fromMillis(start),
        count: fresh ? 1 : count + 1,
        lastSent: Timestamp.fromMillis(now),
      });
      return true;
    }

    tx.set(ref, {
      windowStart: Timestamp.fromMillis(now),
      count: 1,
      lastSent: Timestamp.fromMillis(now),
    });
    return true;
  });
}
