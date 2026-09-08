/// Production-approved API hosts for Remote Config [liveURL] values.
///
/// Only exact host matches are accepted to block subdomain-suffix attacks such as
/// `allowed-host.evil.com`.
const Set<String> allowedApiHosts = {'moi-api.floatwalktiruppur.in'};

/// Default HTTPS port; non-default ports are rejected unless added to [allowedApiPorts].
const Set<int> allowedApiPorts = {443};

/// Returns true when [url] is an approved HTTPS API base URL.
bool isAllowedApiEndpoint(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return false;
  }

  if (uri.scheme != 'https') {
    return false;
  }

  if (uri.userInfo.isNotEmpty) {
    return false;
  }

  final host = uri.host;
  if (host.isEmpty || !allowedApiHosts.contains(host)) {
    return false;
  }

  final port = uri.hasPort ? uri.port : 443;
  if (!allowedApiPorts.contains(port)) {
    return false;
  }

  return true;
}
