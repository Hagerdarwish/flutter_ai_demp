import 'package:flutter/material.dart';

/// A Text widget that auto-detects Arabic/RTL content and applies the
/// correct text direction so Arabic displays right-to-left properly.
class SmartText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SmartText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Returns true if the text contains a significant amount of Arabic characters.
  static bool isRtl(String text) {
    if (text.isEmpty) return false;
    // Count Arabic/Hebrew/Farsi Unicode ranges
    int rtlCount = 0;
    int ltrCount = 0;
    for (final rune in text.runes) {
      if ((rune >= 0x0600 && rune <= 0x06FF) || // Arabic
          (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
          (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
          (rune >= 0xFE70 && rune <= 0xFEFF)) { // Arabic Presentation Forms-B
        rtlCount++;
      } else if (rune >= 0x0041 && rune <= 0x007A) {
        ltrCount++;
      }
    }
    return rtlCount > ltrCount;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = isRtl(text);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        style: style,
        textAlign: textAlign ?? (rtl ? TextAlign.right : TextAlign.left),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// A BulletPoint that auto-detects RTL content.
class SmartBulletPoint extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SmartBulletPoint(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final rtl = SmartText.isRtl(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!rtl) ...[
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Text(text, style: style ?? Theme.of(context).textTheme.bodyMedium)),
            ] else ...[
              Expanded(child: Text(text, textAlign: TextAlign.right, style: style ?? Theme.of(context).textTheme.bodyMedium)),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, left: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
