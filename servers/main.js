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

app.listen(PORT, () => {
  console.log(`JWKS server listening on http://localhost:${PORT}`);
  console.log(
    `Public JWK Set available at http://localhost:${PORT}/.well-known/jwks.json`
  );
});
