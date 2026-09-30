/// Emergency contact numbers, stored in international form.
abstract final class PhoneNumber {
  /// Libya, shown in front of the number field.
  static const countryCode = '+218';

  /// The number in international form, or null when it isn't a valid one.
  ///
  /// Accepts a Libyan number typed the usual ways ("091 234 5678",
  /// "91-234-5678", "+218 91…", "00218 91…") and Arabic-Indic digits.
  /// Numbers that start with + or 00 and another country code are kept.
  static String? normalize(String input) {
    var text = _latinDigits(input).replaceAll(RegExp(r'[\s\-().]'), '');
    var international = false;
    if (text.startsWith('+')) {
      text = text.substring(1);
      international = true;
    } else if (text.startsWith('00')) {
      text = text.substring(2);
      international = true;
    }
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;

    if (international && !text.startsWith('218')) {
      // Another country: E.164 allows up to 15 digits.
      return text.length >= 8 && text.length <= 15 ? '+$text' : null;
    }
    if (text.startsWith('218') && text.length == 12) text = text.substring(3);
    if (text.startsWith('0')) text = text.substring(1);
    // Libyan numbers have 9 digits after the country code.
    return text.length == 9 ? '$countryCode$text' : null;
  }

  static String _latinDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660); // Arabic-Indic
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0); // Persian
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
