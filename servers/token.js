const crypto = require("node:crypto");

/**
 * Create a JWT token signed with the given private key
 * @param {Object} payload - Token payload (claims)
 * @param {crypto.KeyObject} privateKey - Private key for signing
 * @param {Object} publicKey - Public JWK (for kid and alg)
 * @returns {string} Signed JWT token
 */
function createToken(payload, privateKey, publicKey) {
  const header = {
    alg: publicKey.alg,
    typ: "JWT",
    kid: publicKey.kid,
  };

  // Add standard claims
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iat: now,
    jti: crypto.randomUUID(),
    ...payload,
  };

  // Set default expiration (1 hour)
  if (!claims.exp) {
    claims.exp = now + 3600;
  }

  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(claims));
  const signingInput = `${headerB64}.${payloadB64}`;

  let signature;
  if (publicKey.alg === "RS256") {
    signature = crypto.sign("sha256", Buffer.from(signingInput), privateKey);
  } else if (publicKey.alg === "EdDSA") {
    signature = crypto.sign(null, Buffer.from(signingInput), privateKey);
  } else {
    throw new Error(`Unsupported algorithm: ${publicKey.alg}`);
  }

  const signatureB64 = base64UrlEncode(signature);
  return `${signingInput}.${signatureB64}`;
}

function decodeToken(token) {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid JWT format");
  }

  return {
    header: JSON.parse(base64UrlDecode(parts[0])),
    payload: JSON.parse(base64UrlDecode(parts[1])),
  };
}

function base64UrlEncode(input) {
  const buffer = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buffer
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

function base64UrlDecode(input) {
  let base64 = input.replace(/-/g, "+").replace(/_/g, "/");
  const padding = base64.length % 4;
  if (padding) {
    base64 += "=".repeat(4 - padding);
  }
  return Buffer.from(base64, "base64").toString("utf8");
}

module.exports = { createToken, decodeToken, base64UrlEncode, base64UrlDecode };
