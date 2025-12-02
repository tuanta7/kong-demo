const express = require("express");
const { genRsaKeyPair, genEd25519KeyPair } = require("./jwk");

const app = express();
const PORT = process.env.PORT || 3000;

const keyStore = [];

keyStore.push(genRsaKeyPair());
keyStore.push(genRsaKeyPair());
keyStore.push(genEd25519KeyPair());
keyStore.push(genEd25519KeyPair());

app.get("/.well-known/jwks.json", (req, res) => {
  const jwkSet = [];
  keyStore.forEach((v) => {
    jwkSet.push(v.publicKey);
  });

  res.setHeader("Content-Type", "application/jwk-set+json");
  res.json(jwkSet);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`JWKS server listening on http://0.0.0.0:${PORT}`);
  console.log(
    `Public JWK Set available at http://0.0.0.0:${PORT}/.well-known/jwks.json`
  );
});
