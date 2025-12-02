const crypto = require("node:crypto");

function genRsaKeyPair(modulusLength = 2048) {
  const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", {
    modulusLength,
  });

  const pk = publicKey.export({
    format: "jwk",
  });

  pk.alg = "RS256";
  pk.use = "sig";
  pk.kid = crypto.randomBytes(8).toString("hex");

  return { publicKey: pk, privateKey };
}

function genEd25519KeyPair() {
  const { publicKey, privateKey } = crypto.generateKeyPairSync("ed25519");
  const pk = publicKey.export({ format: "jwk" });

  pk.alg = "EdDSA";
  pk.use = "sig";
  pk.kid = crypto.randomBytes(8).toString("hex");

  return { publicKey: pk, privateKey };
}

module.exports = { genRsaKeyPair, genEd25519KeyPair };
