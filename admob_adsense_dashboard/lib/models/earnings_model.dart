class DateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const DateRange({required this.start, required this.end, required this.label});

  static DateRange today() {
    final now = DateTime.now();
    return DateRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day), label: '오늘');
  }

  static DateRange yesterday() {
    final now = DateTime.now();
    final y = now.subtract(const Duration(days: 1));
    return DateRange(start: DateTime(y.year, y.month, y.day), end: DateTime(y.year, y.month, y.day), label: '어제');
  }

  static DateRange last7Days() {
    final now = DateTime.now();
    return DateRange(start: now.subtract(const Duration(days: 6)), end: now, label: '최근 7일');
  }

  static DateRange thisMonth() {
    final now = DateTime.now();
    return DateRange(start: DateTime(now.year, now.month, 1), end: now, label: '이번 달');
  }
}

class EarningsSummary {
  final double estimatedEarnings;
  final double ecpm;
  final int impressions;
  final int clicks;
  final double matchRate;
  final double? previousEarnings;

  const EarningsSummary({required this.estimatedEarnings, required this.ecpm, required this.impressions, required this.clicks, required this.matchRate, this.previousEarnings});

  double? get earningsChange => previousEarnings == null || previousEarnings == 0 ? null : estimatedEarnings - previousEarnings!;
  double? get earningsChangePercent => previousEarnings == null || previousEarnings == 0 ? null : (estimatedEarnings - previousEarnings!) / previousEarnings! * 100;
}

class AppEarnings {
  final String appId;
  final String appName;
  final String platform;
  final String? packageName;
  final double estimatedEarnings;
  final double ecpm;
  final int impressions;

  const AppEarnings({required this.appId, required this.appName, required this.platform, this.packageName, required this.estimatedEarnings, required this.ecpm, required this.impressions});
}

class AdUnitEarnings {
  final String adUnitId;
  final String adUnitName;
  final String adFormat;
  final double estimatedEarnings;
  final double ecpm;
  final int impressions;

  const AdUnitEarnings({required this.adUnitId, required this.adUnitName, required this.adFormat, required this.estimatedEarnings, required this.ecpm, required this.impressions});
}

class AdMobAccount {
  final String publisherId;
  final String name;
  final String currencyCode;
  final String reportingTimeZone;

  const AdMobAccount({required this.publisherId, required this.name, required this.currencyCode, required this.reportingTimeZone});
}

class AdSenseAccount {
  final String accountId;
  final String displayName;
  final String currencyCode;
  final String timeZone;

  const AdSenseAccount({required this.accountId, required this.displayName, required this.currencyCode, required this.timeZone});
}
