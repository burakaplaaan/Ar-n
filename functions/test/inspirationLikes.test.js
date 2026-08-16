"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  applyPublicInspirationLike,
  voteDocId,
  COUNTS_COLLECTION,
  VOTES_COLLECTION,
} = require("../inspirationLikes");

const FieldValue = {
  increment(n) {
    return { _inc: n };
  },
  serverTimestamp() {
    return "ts";
  },
};

function createMemoryDb(seed = {}) {
  const docs = new Map(Object.entries(seed));

  function ref(collection, id) {
    const key = `${collection}/${id}`;
    return { _key: key };
  }

  return {
    _docs: docs,
    collection(name) {
      return {
        doc(id) {
          return ref(name, id);
        },
      };
    },
    async runTransaction(fn) {
      const writes = [];
      const tx = {
        async get(docRef) {
          return {
            exists: docs.has(docRef._key),
            data: () => docs.get(docRef._key),
          };
        },
        set(docRef, data) {
          writes.push({ type: "set", key: docRef._key, data, merge: true });
        },
        delete(docRef) {
          writes.push({ type: "delete", key: docRef._key });
        },
      };
      await fn(tx);
      for (const write of writes) {
        if (write.type === "delete") {
          docs.delete(write.key);
        } else {
          const prev = docs.get(write.key) || {};
          const next = { ...prev };
          for (const [key, value] of Object.entries(write.data)) {
            if (value && typeof value === "object" && "_inc" in value) {
              next[key] = (Number(next[key]) || 0) + value._inc;
            } else {
              next[key] = value;
            }
          }
          docs.set(write.key, next);
        }
      }
    },
  };
}

async function apply(db, { cardId = "v_1", installHash = "abc", liked }) {
  await applyPublicInspirationLike(db, {
    cardId,
    installHash,
    liked,
    FieldValue,
  });
}

test("ilk beğeni sayacı 1 yapar ve oy belgesi oluşturur", async () => {
  const db = createMemoryDb();
  await apply(db, { liked: true });
  assert.equal(db._docs.get(`${COUNTS_COLLECTION}/v_1`).count, 1);
  assert.equal(db._docs.has(`${VOTES_COLLECTION}/${voteDocId("v_1", "abc")}`), true);
});

test("aynı kurulumun ikinci beğenisi sayacı artırmaz", async () => {
  const db = createMemoryDb();
  await apply(db, { liked: true });
  await apply(db, { liked: true });
  assert.equal(db._docs.get(`${COUNTS_COLLECTION}/v_1`).count, 1);
});

test("beğeni geri alınca sayaç düşer ve oy silinir", async () => {
  const db = createMemoryDb();
  await apply(db, { liked: true });
  await apply(db, { liked: false });
  assert.equal(db._docs.get(`${COUNTS_COLLECTION}/v_1`).count, 0);
  assert.equal(db._docs.has(`${VOTES_COLLECTION}/${voteDocId("v_1", "abc")}`), false);
});

test("oyu olmayan geri alma no-op ve negatif saymaz", async () => {
  const db = createMemoryDb();
  await apply(db, { liked: false });
  assert.equal(db._docs.has(`${COUNTS_COLLECTION}/v_1`), false);
});

test("iki kurulum aynı sözde 2 sayar", async () => {
  const db = createMemoryDb();
  await apply(db, { installHash: "one", liked: true });
  await apply(db, { installHash: "two", liked: true });
  assert.equal(db._docs.get(`${COUNTS_COLLECTION}/v_1`).count, 2);
});
