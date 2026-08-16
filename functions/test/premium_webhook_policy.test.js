"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const policy = require("../premium_webhook_policy");

test("new premium SKUs are recognized including lifetime", () => {
  assert.equal(policy.isPremiumProductId("arin_premium_monthly"), true);
  assert.equal(policy.isPremiumProductId("arin_premium_yearly:p1y"), true);
  assert.equal(policy.isPremiumProductId("arin_premium_lifetime"), true);
  assert.equal(policy.isLifetimeProductId("arin_premium_lifetime"), true);
  assert.equal(policy.isLifetimeProductId("arin_premium_monthly"), false);
});

test("launch SKUs stay premium for existing subscribers", () => {
  assert.equal(policy.isPremiumProductId("arin_premium_monthly_launch"), true);
  assert.equal(policy.isPremiumProductId("arin_premium_yearly_launch"), true);
  assert.equal(policy.isPremiumProductId("arin_premium_monthly_launch:p1m"), true);
  assert.equal(policy.isPremiumProductId("arin_premium_yearly_launch:p1y"), true);
  assert.equal(policy.isLifetimeProductId("arin_premium_monthly_launch"), false);
  assert.equal(policy.PREMIUM_PRODUCT_IDS.has("arin_premium_monthly_launch"), true);
  assert.equal(policy.PREMIUM_PRODUCT_IDS.has("arin_premium_yearly_launch"), true);
});

test("lifetime TRANSFER without expiry grants destination", () => {
  const grant = policy.transferDestinationGrant({
    productId: "arin_premium_lifetime",
    entitlementIds: ["premium"],
    activeUntilMs: null,
    nowMs: 1_700_000_000_000,
  });
  assert.deepEqual(grant, {
    active: true,
    expiresAtMs: null,
    lifetime: true,
  });
});

test("subscription TRANSFER without expiry does not become lifetime unless entitlement-only", () => {
  const noEntitlement = policy.transferDestinationGrant({
    productId: "arin_premium_yearly",
    entitlementIds: [],
    activeUntilMs: null,
    nowMs: 1_700_000_000_000,
  });
  assert.equal(noEntitlement.active, false);
  assert.equal(noEntitlement.lifetime, false);

  const entitlementOnly = policy.transferDestinationGrant({
    productId: null,
    entitlementIds: ["premium"],
    activeUntilMs: null,
    nowMs: 1_700_000_000_000,
  });
  assert.equal(entitlementOnly.active, true);
  assert.equal(entitlementOnly.lifetime, true);
});

test("subscription grant without expiry is rejected", () => {
  assert.deepEqual(
    policy.subscriptionGrantExpiresAtMs({
      isLifetime: false,
      expirationAtMs: null,
    }),
    { ok: false, expiresAtMs: null },
  );
  assert.deepEqual(
    policy.subscriptionGrantExpiresAtMs({
      isLifetime: true,
      expirationAtMs: null,
    }),
    { ok: true, expiresAtMs: null },
  );
});

test("later subscription events do not overwrite lifetime", () => {
  const existing = {
    active: true,
    productId: "arin_premium_lifetime",
    expiresAt: null,
  };
  assert.equal(
    policy.shouldPreserveLifetime({
      existingData: existing,
      eventType: "EXPIRATION",
      incomingProductId: "arin_premium_yearly",
    }),
    true,
  );
  assert.equal(
    policy.shouldPreserveLifetime({
      existingData: existing,
      eventType: "CANCELLATION",
      incomingProductId: "arin_premium_lifetime",
    }),
    false,
  );
});

test("inactive lifetime leftovers are not frozen", () => {
  const tombstone = {
    active: false,
    productId: "arin_premium_lifetime",
    expiresAt: null,
  };
  for (const [eventType, incomingProductId] of [
    ["TRANSFER", "arin_premium_lifetime"],
    ["NON_RENEWING_PURCHASE", "arin_premium_lifetime"],
    ["INITIAL_PURCHASE", "arin_premium_monthly"],
  ]) {
    assert.equal(
      policy.shouldPreserveLifetime({
        existingData: tombstone,
        eventType,
        incomingProductId,
      }),
      false,
      `${eventType} ${incomingProductId}`,
    );
  }
});
