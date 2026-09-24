import 'dart:typed_data';

/// Crockford's base32 alphabet: no I, L, O or U, so codes read aloud or
/// typed from paper are hard to get wrong.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

String encodeCrockfordBase32(List<int> bytes) {
  final output = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8) | (byte & 0xff);
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      output.write(_alphabet[(buffer >> bits) & 31]);
    }
    buffer &= (1 << bits) - 1;
  }
  if (bits > 0) {
    output.write(_alphabet[(buffer << (5 - bits)) & 31]);
  }
  return output.toString();
}

/// Decodes Crockford base32, ignoring spaces and dashes and accepting the
/// usual look-alikes (O for 0, I and L for 1). Returns null for anything else
/// or when the trailing padding bits are not zero.
Uint8List? decodeCrockfordBase32(String input) {
  final output = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final character in input.toUpperCase().split('')) {
    if (character == '-' || character.trim().isEmpty) continue;
    final normalized = switch (character) {
      'O' => '0',
      'I' || 'L' => '1',
      _ => character,
    };
    final value = _alphabet.indexOf(normalized);
    if (value < 0) return null;
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      output.add((buffer >> bits) & 0xff);
      buffer &= (1 << bits) - 1;
    }
  }
  if (buffer != 0) return null;
  return Uint8List.fromList(output);
}
