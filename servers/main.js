const express = require("express");
const { genRsaKeyPair, genEd25519KeyPair } = require("./jwk");
const { createToken, decodeToken } = require("./token");
const { initRedis, isRedisAvailable, blacklistToken } = require("./redis");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

const keyStore = [];

keyStore.push(genEd25519KeyPair());
keyStore.push(genEd25519KeyPair());
keyStore.push(genRsaKeyPair());
keyStore.push(genRsaKeyPair());

app.get("/.well-known/jwks.json", (req, res) => {
  const jwkSet = [];
  keyStore.forEach((v) => {
    jwkSet.push(v.publicKey);
  });

  res.setHeader("Content-Type", "application/jwk-set+json");
  res.json(jwkSet);
});

app.post("/token", (req, res) => {
  try {
    const { sub, iss, aud, exp, keyIndex = 0, ...customClaims } = req.body;

    // Select key pair (default to first RSA key)
    const idx = Math.min(keyIndex, keyStore.length - 1);
    const { publicKey, privateKey } = keyStore[idx];

    const payload = {
      sub: sub || "anonymous",
      iss: iss || "jwks-server",
      aud: aud || "api",
      ...customClaims,
    };

    // Set expiration if provided
    if (exp) {
      payload.exp = Math.floor(Date.now() / 1000) + exp;
    }

    const token = createToken(payload, privateKey, publicKey);
    const decoded = decodeToken(token);

    res.json({
      token,
      jti: decoded.payload.jti,
      exp: decoded.payload.exp,
      kid: decoded.header.kid,
      alg: decoded.header.alg,
    });
  } catch (err) {
    console.error("Token creation error:", err);
    res.status(500).json({ error: err.message });
  }
});

app.post("/blacklist", async (req, res) => {
  try {
    const { token } = req.body;
    const decoded = decodeToken(token);

    const jti = decoded.payload.jti;
    const exp = decoded.payload.exp;

    if (!jti) {
      return res.status(400).json({ error: "jti is required" });
    }

    if (!isRedisAvailable()) {
      return res.status(503).json({ error: "Redis not available" });
    }

    const result = await blacklistToken(jti, exp);

    if (!result.success && result.expired) {
      return res.json({
        message: "Token already expired, not blacklisted",
        jti,
      });
    }

    console.log(`Token blacklisted: ${jti}`);
    res.json({
      message: "Token blacklisted successfully",
      jti,
      key: result.key,
    });
  } catch (err) {
    console.error("Blacklist error:", err);
    res.status(500).json({ error: err.message });
  }
});

async function start() {
  await initRedis();
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`JWKS server listening on http://0.0.0.0:${PORT}`);
  });
}

start().catch(console.error);
