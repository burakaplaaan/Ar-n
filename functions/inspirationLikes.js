"use strict";

const COUNTS_COLLECTION = "inspiration_like_counts";
const VOTES_COLLECTION = "inspiration_like_votes";

function voteDocId(cardId, installHash) {
  return `${cardId}__${installHash}`;
}

/**
 * Kurulum başına tek oy. Beğeni +1, geri alma -1; tekrar çağrı no-op.
 */
async function applyPublicInspirationLike(db, {
  cardId,
  installHash,
  liked,
  FieldValue,
}) {
  const voteRef = db.collection(VOTES_COLLECTION).doc(
    voteDocId(cardId, installHash),
  );
  const countRef = db.collection(COUNTS_COLLECTION).doc(cardId);

  await db.runTransaction(async (tx) => {
    const voteSnap = await tx.get(voteRef);
    const countSnap = await tx.get(countRef);
    const current = Number(countSnap.data()?.count) || 0;

    if (liked) {
      if (voteSnap.exists) return;
      tx.set(voteRef, {
        cardId,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(countRef, {
        count: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }

    if (!voteSnap.exists) return;
    tx.delete(voteRef);
    tx.set(countRef, {
      count: current <= 0 ? 0 : FieldValue.increment(-1),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

module.exports = {
  applyPublicInspirationLike,
  voteDocId,
  COUNTS_COLLECTION,
  VOTES_COLLECTION,
};
