"use strict";

const PREMIUM_PRODUCT_IDS = new Set([
  "arin_premium_monthly",
  "arin_premium_yearly",
  "arin_premium_lifetime",
  "arin_premium_monthly_launch",
  "arin_premium_yearly_launch",
]);

const LIFETIME_PRODUCT_IDS = new Set(["arin_premium_lifetime"]);

function extractBaseProductId(productId) {
  if (!productId || typeof productId !== "string") return null;
  return productId.split(":")[0];
}

function isLifetimeProductId(productId) {
  const baseProductId = extractBaseProductId(productId);
  return Boolean(
    (productId && LIFETIME_PRODUCT_IDS.has(productId)) ||
      (baseProductId && LIFETIME_PRODUCT_IDS.has(baseProductId)),
  );
}

function isPremiumProductId(productId) {
  const baseProductId = extractBaseProductId(productId);
  return Boolean(
    (productId && PREMIUM_PRODUCT_IDS.has(productId)) ||
      (baseProductId && PREMIUM_PRODUCT_IDS.has(baseProductId)),
  );
}

function eventHasPremiumEntitlement(event) {
  const ids = event && event.entitlement_ids;
  return Array.isArray(ids) && ids.includes("premium");
}

function isLifetimeEntitlementRecord(data) {
  if (!data || data.active !== true) return false;
  return isLifetimeProductId(data.productId) || data.expiresAt == null;
}

function shouldPreserveLifetime({ existingData, eventType, incomingProductId }) {
  if (!isLifetimeEntitlementRecord(existingData)) return false;
  const incomingLifetime = isLifetimeProductId(incomingProductId);
  if (
    incomingLifetime &&
    (eventType === "CANCELLATION" || eventType === "EXPIRATION")
  ) {
    return false;
  }
  return true;
}

function transferDestinationGrant({
  productId,
  entitlementIds,
  activeUntilMs,
  nowMs,
}) {
  const hasPremiumEntitlement =
    Array.isArray(entitlementIds) && entitlementIds.includes("premium");
  if (isLifetimeProductId(productId) || (hasPremiumEntitlement && !activeUntilMs)) {
    return { active: true, expiresAtMs: null, lifetime: true };
  }
  if (!activeUntilMs) {
    return { active: false, expiresAtMs: null, lifetime: false };
  }
  return {
    active: activeUntilMs > nowMs,
    expiresAtMs: activeUntilMs,
    lifetime: false,
  };
}

function subscriptionGrantExpiresAtMs({ isLifetime, expirationAtMs }) {
  if (isLifetime) return { ok: true, expiresAtMs: null };
  const value = Number(expirationAtMs);
  if (!Number.isFinite(value) || value <= 0) {
    return { ok: false, expiresAtMs: null };
  }
  return { ok: true, expiresAtMs: value };
}

module.exports = {
  PREMIUM_PRODUCT_IDS,
  LIFETIME_PRODUCT_IDS,
  extractBaseProductId,
  isLifetimeProductId,
  isPremiumProductId,
  eventHasPremiumEntitlement,
  isLifetimeEntitlementRecord,
  shouldPreserveLifetime,
  transferDestinationGrant,
  subscriptionGrantExpiresAtMs,
};
