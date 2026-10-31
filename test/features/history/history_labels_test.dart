import 'package:character_lens/features/history/history_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 31, 14, 30);

  String ago(Duration before) => agoText(now.subtract(before), now);

  test('under a minute is just now', () {
    expect(ago(Duration.zero), 'Just now');
    expect(ago(const Duration(seconds: 59)), 'Just now');
  });

  test('a time in the future is just now, not a negative number', () {
    expect(agoText(now.add(const Duration(minutes: 5)), now), 'Just now');
  });

  test('under an hour is minutes', () {
    expect(ago(const Duration(minutes: 1)), '1 min ago');
    expect(ago(const Duration(minutes: 59)), '59 min ago');
  });

  test('later the same day is hours', () {
    expect(ago(const Duration(hours: 1)), '1 h ago');
    expect(ago(const Duration(hours: 14)), '14 h ago');
  });

  test('the day before is yesterday, even a few hours ago', () {
    expect(ago(const Duration(hours: 15)), 'Yesterday');
    expect(
      agoText(DateTime(2026, 10, 30, 23, 59), DateTime(2026, 10, 31, 0, 1)),
      '2 min ago',
    );
    expect(
      agoText(DateTime(2026, 10, 30, 9), DateTime(2026, 10, 31, 9, 5)),
      'Yesterday',
    );
  });

  test('older days are counted', () {
    expect(ago(const Duration(days: 2)), '2 days ago');
    expect(ago(const Duration(days: 9)), '9 days ago');
  });
}
