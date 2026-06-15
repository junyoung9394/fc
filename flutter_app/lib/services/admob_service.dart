import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earnings_model.dart';

class AdMobService {
  static const _base = 'https://admob.googleapis.com/v1';

  final String accessToken;
  AdMobService(this.accessToken);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  Future<List<AdMobAccount>> listAccounts() async {
    final res = await http.get(Uri.parse('$_base/accounts'), headers: _headers);
    if (res.statusCode != 200) throw Exception('AdMob 계정 조회 실패: ${res.statusCode}');
    final data = json.decode(res.body) as Map<String, dynamic>;
    final accounts = data['account'] as List? ?? [];
    return accounts
        .map((a) => AdMobAccount(
              publisherId: a['publisherId'] ?? '',
              name: a['name'] ?? '',
              currencyCode: a['currencyCode'] ?? 'KRW',
              reportingTimeZone: a['reportingTimeZone'] ?? 'Asia/Seoul',
            ))
        .toList();
  }

  Future<EarningsSummary> getNetworkReport(String publisherId, DateRange range) async {
    final body = {
      'reportSpec': {
        'dateRange': {
          'startDate': _dateMap(range.start),
          'endDate': _dateMap(range.end),
        },
        'metrics': ['ESTIMATED_EARNINGS', 'ECPM', 'IMPRESSIONS', 'CLICKS', 'MATCH_RATE'],
      },
    };
    final res = await http.post(
      Uri.parse('$_base/accounts/$publisherId/networkReport:generate'),
      headers: _headers,
      body: json.encode(body),
    );
    if (res.statusCode != 200) throw Exception('AdMob 리포트 조회 실패: ${res.statusCode}');

    final rows = (json.decode(res.body) as List)
        .where((r) => r['row'] != null)
        .toList();

    double earnings = 0, ecpm = 0, matchRate = 0;
    int impressions = 0, clicks = 0;
    for (final r in rows) {
      final m = r['row']['metricValues'] as Map;
      earnings += _micro(m['ESTIMATED_EARNINGS']);
      ecpm += _micro(m['ECPM']);
      impressions += _int(m['IMPRESSIONS']);
      clicks += _int(m['CLICKS']);
      matchRate += _double(m['MATCH_RATE']);
    }
    return EarningsSummary(
      estimatedEarnings: earnings,
      ecpm: rows.isEmpty ? 0 : ecpm / rows.length,
      impressions: impressions,
      clicks: clicks,
      matchRate: rows.isEmpty ? 0 : matchRate / rows.length,
    );
  }

  Future<List<AppEarnings>> getAppReport(String publisherId, DateRange range) async {
    final body = {
      'reportSpec': {
        'dateRange': {
          'startDate': _dateMap(range.start),
          'endDate': _dateMap(range.end),
        },
        'dimensions': ['APP'],
        'metrics': ['ESTIMATED_EARNINGS', 'ECPM', 'IMPRESSIONS'],
      },
    };
    final res = await http.post(
      Uri.parse('$_base/accounts/$publisherId/networkReport:generate'),
      headers: _headers,
      body: json.encode(body),
    );
    if (res.statusCode != 200) throw Exception('앱별 리포트 조회 실패');

    final rows = (json.decode(res.body) as List)
        .where((r) => r['row'] != null)
        .toList();

    return rows.map((r) {
      final dims = r['row']['dimensionValues'] as Map;
      final metrics = r['row']['metricValues'] as Map;
      final appDim = dims['APP'] as Map;
      return AppEarnings(
        appId: appDim['value'] ?? '',
        appName: appDim['displayLabel'] ?? appDim['value'] ?? '',
        platform: 'ANDROID',
        estimatedEarnings: _micro(metrics['ESTIMATED_EARNINGS']),
        ecpm: _micro(metrics['ECPM']),
        impressions: _int(metrics['IMPRESSIONS']),
      );
    }).toList()
      ..sort((a, b) => b.estimatedEarnings.compareTo(a.estimatedEarnings));
  }

  Future<List<AdUnitEarnings>> getAdUnitReport(String publisherId, DateRange range) async {
    final body = {
      'reportSpec': {
        'dateRange': {
          'startDate': _dateMap(range.start),
          'endDate': _dateMap(range.end),
        },
        'dimensions': ['AD_UNIT', 'FORMAT'],
        'metrics': ['ESTIMATED_EARNINGS', 'ECPM', 'IMPRESSIONS'],
      },
    };
    final res = await http.post(
      Uri.parse('$_base/accounts/$publisherId/networkReport:generate'),
      headers: _headers,
      body: json.encode(body),
    );
    if (res.statusCode != 200) throw Exception('광고 단위 리포트 조회 실패');

    final rows = (json.decode(res.body) as List)
        .where((r) => r['row'] != null)
        .toList();

    final merged = <String, AdUnitEarnings>{};
    for (final r in rows) {
      final dims = r['row']['dimensionValues'] as Map;
      final metrics = r['row']['metricValues'] as Map;
      final unitDim = dims['AD_UNIT'] as Map;
      final formatDim = (dims['FORMAT'] as Map?) ?? {};
      final id = unitDim['value'] as String? ?? '';
      final e = _micro(metrics['ESTIMATED_EARNINGS']);
      final ecpm = _micro(metrics['ECPM']);
      final imp = _int(metrics['IMPRESSIONS']);
      final existing = merged[id];
      if (existing == null) {
        merged[id] = AdUnitEarnings(
          adUnitId: id,
          adUnitName: unitDim['displayLabel'] ?? id,
          adFormat: formatDim['displayLabel'] ?? '',
          estimatedEarnings: e,
          ecpm: ecpm,
          impressions: imp,
        );
      } else {
        merged[id] = AdUnitEarnings(
          adUnitId: existing.adUnitId,
          adUnitName: existing.adUnitName,
          adFormat: existing.adFormat,
          estimatedEarnings: existing.estimatedEarnings + e,
          ecpm: (existing.ecpm + ecpm) / 2,
          impressions: existing.impressions + imp,
        );
      }
    }
    return merged.values.toList()
      ..sort((a, b) => b.estimatedEarnings.compareTo(a.estimatedEarnings));
  }

  Map<String, int> _dateMap(DateTime d) => {'year': d.year, 'month': d.month, 'day': d.day};

  double _micro(dynamic v) {
    if (v == null) return 0;
    if (v['microsValue'] != null) return double.parse(v['microsValue'].toString()) / 1000000;
    return double.tryParse((v['doubleValue'] ?? '0').toString()) ?? 0;
  }

  int _int(dynamic v) {
    if (v == null) return 0;
    return int.tryParse((v['integerValue'] ?? '0').toString()) ?? 0;
  }

  double _double(dynamic v) {
    if (v == null) return 0;
    return double.tryParse((v['doubleValue'] ?? '0').toString()) ?? 0;
  }
}
