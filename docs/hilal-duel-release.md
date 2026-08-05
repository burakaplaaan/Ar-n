# Hilal Düellosu — Release Checklist

## Cloud Functions (`europe-west1`)

Callable (App Check enforced):

- `createQuizSession`
- `getQuizProfile`
- `beginQuizReward`
- `claimQuizReward`
- `startQuizMatch`
- `cancelQuizMatchmaking`
- `pollQuizMatch`
- `getQuizMatch`
- `submitQuizAnswer`

Scheduled:

- `cleanupAbandonedQuizQueues` — every 5 minutes; refunds abandoned `waiting` queues once via `quiz_heart_charges` ledger

Shared HTTP (unchanged entrypoint, quiz-aware):

- `rewardedAdSsv` — accepts Prayer Circle **and** quiz `custom_data` v2

### Deploy

```bash
cd functions
npm test
firebase deploy --only functions:createQuizSession,functions:getQuizProfile,functions:beginQuizReward,functions:claimQuizReward,functions:startQuizMatch,functions:cancelQuizMatchmaking,functions:pollQuizMatch,functions:getQuizMatch,functions:submitQuizAnswer,functions:cleanupAbandonedQuizQueues,functions:rewardedAdSsv
```

Or full functions deploy after review:

```bash
firebase deploy --only functions
```

## Firestore

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Fail-closed collections

Client R/W denied for: `quiz_installations`, `quiz_players`, `quiz_queue`, `quiz_matches`, `quiz_reward_proofs`, `quiz_reward_transactions`, `quiz_rate_limits`, `quiz_heart_charges`.

### TTL policies (`expiresAt`)

| Collection | Role |
|---|---|
| `quiz_installations` | Session binding cleanup (~180d) |
| `quiz_queue` | Waiting docs use **long** TTL (~7d) so cleanup can refund first; idle/matched set short TTL after settle |
| `quiz_matches` | Match retention (~24h) |
| `quiz_reward_proofs` / `quiz_reward_transactions` | Reward ledger |
| `quiz_rate_limits` | 5‑minute windows, 24h TTL |
| `quiz_heart_charges` | Heart charge/refund idempotency ledger (~30d) |

**Important:** Do not shorten waiting-queue TTL below the cleanup interval. Hearts are refunded by `cleanupAbandonedQuizQueues` and claim-on-reentry in `getQuizProfile` / `startQuizMatch` / `cancelQuizMatchmaking` / `pollQuizMatch` before docs become idle for TTL deletion.

## Rewarded ads / SSV

- Ad unit: existing `ArinAdUnit.rewardedUnlock` (do not invent IDs).
- Quiz `custom_data` (base64url JSON):

```json
{ "version": 2, "kind": "quiz", "proofId": "<20-64 alnum>" }
```

- Prayer Circle remains `{ version: 2, kind: "prayer", ... }` (or legacy shape decoded by `_decodePrayerRewardCustomData`).
- `rewardedAdSsv` fail-closed: invalid/unknown custom_data → `Ignored` / retry; quiz proofs written to `quiz_reward_proofs` + `quiz_reward_transactions`.
- Client must not trust AdMob callbacks alone; always `claimQuizReward` after SSV marks proof `rewarded`.
- Double claim is idempotent: consumed / already-doubled returns success without second hilal increment. Match payload includes `doubled: true`.

## App Check

All quiz callables use `enforceAppCheck: true`. Debug builds need valid App Check tokens for europe-west1.

### Emulator / local debug

Release APK on an emulator **fails Play Integrity** when `enforceAppCheck` is on.

**Temporary (current):** quiz + prayer callables deploy with `ENFORCE_APP_CHECK = false` / `ENFORCE_PRAYER_APP_CHECK = false` so the emulator works without debug tokens. **Set both back to `true` before store/prod.**

Long-term: debug install (`flutter run`) + App Check debug token `8f3c2a91-6e4b-4d7a-9c1e-5b8a0f2d6e73` in Console → Manage debug tokens.

## Client verification

1. Hub card → lobby loads profile + resumes waiting/matched queue if present.
2. Start match → heart consumed; cancel within search → heart refunded once; back/swipe during search awaits cancel.
3. 15s search → bot with “Hızlı Rakip”; answers rejected before `roundStartedAtMs`.
4. Result → optional double SSV once; rematch respects hearts; interstitial every 2 completed free matches on lobby return only.
5. Free players receive hearts only from rewarded ads; Premium players have unlimited matches. There is no daily free-heart path.
6. Google/Apple signed-in users keep real auth (custom token only if `currentUser == null`).

## Content caveat

`functions/data/islamic_quiz_questions.json` (300) is structurally validated in CI tests; it is **not** a scholarly-certified edition. Schedule editorial review before marketing claims.
