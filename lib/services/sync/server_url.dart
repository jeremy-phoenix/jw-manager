/// Validates a sync server address typed by a person.
///
/// Only `https://` is accepted, except plain `http://` to a loopback or
/// Android-emulator host address for local development. Throws
/// [FormatException] with a message suitable for display.
Uri parseSyncServerUrl(String input) {
  final text = input.trim();
  if (text.isEmpty) {
    throw const FormatException('Enter the sync server address.');
  }
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException(
      'Enter a full address, for example https://sync.example.org.',
    );
  }
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    throw const FormatException(
      'The server address must not contain a user name, query or fragment.',
    );
  }
  final scheme = uri.scheme.toLowerCase();
  final allowed =
      scheme == 'https' ||
      (scheme == 'http' && _isLocalDevelopmentHost(uri.host));
  if (!allowed) {
    throw const FormatException(
      'The sync server must use https:// so data and tokens are encrypted in transit.',
    );
  }
  var path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return uri.replace(scheme: scheme, path: path);
}

bool _isLocalDevelopmentHost(String host) =>
    host == 'localhost' ||
    host == '127.0.0.1' ||
    host == '::1' ||
    host == '10.0.2.2';
