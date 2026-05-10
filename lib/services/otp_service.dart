import 'dart:convert';
import 'package:crypto/crypto.dart';

class OTPService {
  static String generateTOTP(String secret, {int windowSeconds = 30}) {
    final int time = (DateTime.now().millisecondsSinceEpoch ~/ (windowSeconds * 1000));
    final List<int> secretBytes = utf8.encode(secret);
    final List<int> timeBytes = utf8.encode(time.toString());
    
    final hmac = Hmac(sha1, secretBytes);
    final digest = hmac.convert(timeBytes);
    
    final List<int> bytes = digest.bytes;
    final int offset = bytes[bytes.length - 1] & 0xf;
    
    final int binary = ((bytes[offset] & 0x7f) << 24) |
                       ((bytes[offset + 1] & 0xff) << 16) |
                       ((bytes[offset + 2] & 0xff) << 8) |
                       (bytes[offset + 3] & 0xff);
                       
    return (binary % 1000000).toString().padLeft(6, '0');
  }
}
