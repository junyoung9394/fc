import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earnings_model.dart';

class AdSenseService {
  static const _base = 'https://adsense.googleapis.com/v2';

  final String accessToken;
  AdSenseService(this.accessToken);

  Map<String, String> get _headers => {'Authorization': 'Bearer $accessToken'};

  Future<List<AdSenseAccount>> listAccounts() async {
    final res = await http.get(Uri.parse('$_base/accounts'), headers: _headers);
    if (res.statusCode != 200) throw Exception('AdSense 계정 조회 실패: ${res.statusCode}');
    final data = json.decode(res.body) as Map<String, dynamic>;
    final accounts = data['accounts'] as List? ?? [];
    return accounts
        .map((a) => AdSenseAccount(
              accountId: a['name'] ?? '',
              displayName: a['displayName'] ?? '',
              currencyCode: a['currencyCode'] ?? 'KRW',
              timeZone: a['timeZone']?['id'] ?? 'Asia/Seoul',
            ))
        .toList();
  }

  Future<EarningsSummary> getReport(String accountId, DateRange range) async {
    final uri = Uri.parse('$_base/$accountId/reports:generate').replace(
      queryParameters: {
        'dateRange': 'CUSTOM',
        'startDate.year': range.start.year.toString(),
        'startDate.month': range.start.month.toString(),
        'startDate.day': range.start.day.toString(),
        'endDate.year': range.end.year.toString(),
        'endDate.month': range.end.month.toString(),
        'endDate.day': range.end.day.toString(),
        'metrics': 'ESTIMATED_EARNINGS,IMPRESSIONS,CLICKS',
        'currencyCode': 'KRW',
      },
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('AdSense 리포트 조회 실패: ${res.statusCode}');

    final data = json.decode(res.body) as Map<String, dynamic>;
    final cells = data['totals']?['cells'] as List? ?? [];

    final earnings = double.tryParse(cells.isNotEmpty ? cells[0]['value']?.toString() ?? '0' : '0') ?? 0;
    final impressions = int.tryParse(cells.length > 1 ? cells[1]['value']?.toString() ?? '0' : '0') ?? 0;
    final clicks = int.tryParse(cells.length > 2 ? cells[2]['value']?.toString() ?? '0' : '0') ?? 0;
    final ecpm = impressions > 0 ? earnings / impressions * 1000 : 0.0;

    return EarningsSummary(
      estimatedEarnings: earnings,
      ecpm: ecpm,
      impressions: impressions,
      clicks: clicks,
      matchRate: 0,
    );
  }
}
