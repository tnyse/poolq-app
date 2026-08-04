import 'dart:convert';

/// MD5 digest as hex (for Gravatar). No extra package required.
String md5Hex(String input) {
  final bytes = utf8.encode(input);
  final digest = _Md5().convert(bytes);
  return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Build a Gravatar URL from an email address.
String? gravatarUrl(
  String? email, {
  int size = 200,
  String defaultImage = 'identicon',
}) {
  final normalized = email?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty || !normalized.contains('@')) return null;
  final hash = md5Hex(normalized);
  return 'https://www.gravatar.com/avatar/$hash?s=$size&d=$defaultImage';
}

class _Md5 {
  static const _r = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
  ];

  static const _k = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a,
    0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
    0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
    0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
    0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
    0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  ];

  List<int> convert(List<int> message) {
    var a0 = 0x67452301;
    var b0 = 0xefcdab89;
    var c0 = 0x98badcfe;
    var d0 = 0x10325476;

    final bitLen = message.length * 8;
    final padded = List<int>.from(message)..add(0x80);
    while ((padded.length % 64) != 56) {
      padded.add(0);
    }
    for (var i = 0; i < 8; i++) {
      padded.add((bitLen >> (8 * i)) & 0xff);
    }

    for (var offset = 0; offset < padded.length; offset += 64) {
      final w = List<int>.filled(16, 0);
      for (var i = 0; i < 16; i++) {
        final j = offset + i * 4;
        w[i] = padded[j] |
            (padded[j + 1] << 8) |
            (padded[j + 2] << 16) |
            (padded[j + 3] << 24);
      }

      var a = a0, b = b0, c = c0, d = d0;
      for (var i = 0; i < 64; i++) {
        late int f;
        late int g;
        if (i < 16) {
          f = (b & c) | ((~b) & d);
          g = i;
        } else if (i < 32) {
          f = (d & b) | ((~d) & c);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | (~d));
          g = (7 * i) % 16;
        }
        f = _add(f, a);
        f = _add(f, _k[i]);
        f = _add(f, w[g]);
        a = d;
        d = c;
        c = b;
        b = _add(b, _rotl(f, _r[i]));
      }
      a0 = _add(a0, a);
      b0 = _add(b0, b);
      c0 = _add(c0, c);
      d0 = _add(d0, d);
    }

    return [..._toBytes(a0), ..._toBytes(b0), ..._toBytes(c0), ..._toBytes(d0)];
  }

  static int _add(int x, int y) => (x + y) & 0xffffffff;
  static int _rotl(int x, int n) =>
      ((x << n) | ((x & 0xffffffff) >> (32 - n))) & 0xffffffff;
  static List<int> _toBytes(int v) => [
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ];
}
