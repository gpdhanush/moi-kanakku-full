const assert = require("assert");
const {
  publicAdminSessionPayload,
  extractAccessToken,
  extractRefreshToken,
  ACCESS_COOKIE,
  REFRESH_COOKIE,
} = require("./adminCookieAuth");

function testPublicPayloadStripsTokens() {
  const csrf = "csrf-abc";
  const out = publicAdminSessionPayload(
    {
      id: 1,
      name: "Admin",
      token: "jwt-access",
      accessToken: "jwt-access",
      refreshToken: "jwt-refresh",
      email: "a@b.com",
    },
    csrf,
  );
  assert.strictEqual(out.csrfToken, csrf);
  assert.strictEqual(out.email, "a@b.com");
  assert.strictEqual(out.token, undefined);
  assert.strictEqual(out.accessToken, undefined);
  assert.strictEqual(out.refreshToken, undefined);
}

function testExtractPrefersBearer() {
  const req = {
    headers: { authorization: "Bearer abc.def.ghi" },
    cookies: { [ACCESS_COOKIE]: "cookie-token" },
  };
  const { token, source } = extractAccessToken(req);
  assert.strictEqual(token, "abc.def.ghi");
  assert.strictEqual(source, "bearer");
}

function testExtractFallsBackToCookie() {
  const req = {
    headers: {},
    cookies: { [ACCESS_COOKIE]: "cookie-token" },
  };
  const { token, source } = extractAccessToken(req);
  assert.strictEqual(token, "cookie-token");
  assert.strictEqual(source, "cookie");
}

function testRefreshFromCookie() {
  const req = {
    body: {},
    cookies: { [REFRESH_COOKIE]: "refresh-cookie" },
  };
  const { token, source } = extractRefreshToken(req);
  assert.strictEqual(token, "refresh-cookie");
  assert.strictEqual(source, "cookie");
}

testPublicPayloadStripsTokens();
testExtractPrefersBearer();
testExtractFallsBackToCookie();
testRefreshFromCookie();
console.log("adminCookieAuth.test.js: all assertions passed");
