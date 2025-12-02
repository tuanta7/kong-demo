const { createClient } = require("redis");

const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

let redisClient = null;

async function initRedis() {
  redisClient = createClient({ url: REDIS_URL });
  redisClient.on("error", (err) => console.error("Redis Client Error:", err));
  await redisClient.connect();
  console.log("Connected to Redis at", REDIS_URL);
}

function getRedisClient() {
  return redisClient;
}

function isRedisAvailable() {
  return redisClient && redisClient.isOpen;
}

async function blacklistToken(jti, exp) {
  if (!isRedisAvailable()) {
    throw new Error("Redis not available");
  }

  const key = `bl:${jti}`;

  if (exp) {
    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) {
      await redisClient.setEx(key, ttl, "1");
      return { success: true, key };
    } else {
      return { success: false, expired: true };
    }
  } else {
    await redisClient.set(key, "1");
    return { success: true, key };
  }
}

module.exports = {
  initRedis,
  getRedisClient,
  isRedisAvailable,
  blacklistToken,
};
