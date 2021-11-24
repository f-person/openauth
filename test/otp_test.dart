import 'package:flutter_test/flutter_test.dart';
import 'package:otp/otp.dart';

void main() {
  test('Verification of the TOTP Generation Algorithm is correct', () {
    final code = OTP.generateTOTPCodeString('J22U6B3WIWRRBTAV',
        DateTime.parse('2019-01-01 00:00:00.000 Z').millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1, interval: 30, isGoogle: true);
    expect(code, equals('793957'));
  });

  test('Verification of HOTP Generation Algorithm is Correct', () {
    final code = OTP.generateHOTPCodeString('JBSWY3DPEHPK3PXP', 0,
        length: 6, algorithm: Algorithm.SHA1);
    expect(code, equals('282760'));
  });
}
