const AUTH_PROVIDER_VALUES = ['email', 'google', 'mobile_app', 'admin'];

function normalizeSignupType(value) {
  if (value == null || value === '') return 'email';
  const normalized = String(value).trim().toLowerCase();
  if (AUTH_PROVIDER_VALUES.includes(normalized)) return normalized;
  if (normalized === 'mobileapp') return 'mobile_app';
  if (normalized === 'googleoauth' || normalized === 'google_oauth') return 'google';
  return 'email';
}

function toBooleanFlag(value) {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value === 1;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['1', 'true', 'yes', 'y'].includes(normalized)) return true;
    if (['0', 'false', 'no', 'n', ''].includes(normalized)) return false;
  }
  return Boolean(value);
}

function buildAuthSummary(row = {}) {
  const storedSignupType = normalizeSignupType(
    row.signup_type ?? row.signupType ?? row.auth_source ?? row.authentication_method,
  );
  const googleLinked = Boolean(row.google_id ?? row.googleId);

  return {
    signupType: googleLinked ? 'google' : storedSignupType,
    googleLinked,
    passwordSet: toBooleanFlag(row.password_set ?? row.passwordSet ?? false),
    emailVerified: toBooleanFlag(row.email_verified ?? row.emailVerified ?? false),
  };
}

module.exports = {
  AUTH_PROVIDER_VALUES,
  normalizeSignupType,
  toBooleanFlag,
  buildAuthSummary,
};
