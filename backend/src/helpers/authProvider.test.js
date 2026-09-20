const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeSignupType, AUTH_PROVIDER_VALUES, buildAuthSummary } = require('./authProvider');

test('normalizeSignupType keeps supported provider names consistent', () => {
  assert.equal(normalizeSignupType('GOOGLE'), 'google');
  assert.equal(normalizeSignupType('email '), 'email');
  assert.equal(normalizeSignupType('mobile_app'), 'mobile_app');
  assert.equal(normalizeSignupType('admin'), 'admin');
  assert.equal(normalizeSignupType(undefined), 'email');
});

test('buildAuthSummary exposes required provider metadata', () => {
  const summary = buildAuthSummary({
    signup_type: 'google',
    google_id: 'sub-123',
    password_set: 0,
    email_verified: 1,
  });

  assert.deepEqual(summary, {
    signupType: 'google',
    googleLinked: true,
    passwordSet: false,
    emailVerified: true,
  });

  assert.ok(AUTH_PROVIDER_VALUES.includes('google'));
});
