import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/earnings_model.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';
import '../services/adsense_service.dart';
import '../widgets/earnings_card.dart';

enum _DateFilter { today, yesterday, last7, thisMonth, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _DateFilter _filter = _DateFilter.today;
  DateRange? _customRange;
  EarningsSummary? _admobSummary, _adsenseSummary;
  List<AppEarnings> _apps = [];
  List<AdUnitEarnings> _adUnits = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _loadData()); }

  DateRange get _range {
    switch (_filter) {
      case _DateFilter.today: return DateRange.today();
      case _DateFilter.yesterday: return DateRange.yesterday();
      case _DateFilter.last7: return DateRange.last7Days();
      case _DateFilter.thisMonth: return DateRange.thisMonth();
      case _DateFilter.custom: return _customRange ?? DateRange.today();
    }
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await context.read<AuthService>().getAccessToken();
      if (token == null) throw Exception('로그인이 필요합니다.');
      final admob = AdMobService(token);
      final accounts = await admob.listAccounts();
      if (accounts.isNotEmpty) {
        final pubId = accounts.first.publisherId;
        _admobSummary = await admob.getNetworkReport(pubId, _range);
        _apps = await admob.getAppReport(pubId, _range);
        _adUnits = await admob.getAdUnitReport(pubId, _range);
      }
      try {
        final adsense = AdSenseService(token);
        final as = await adsense.listAccounts();
        if (as.isNotEmpty) _adsenseSummary = await adsense.getReport(as.first.accountId, _range);
      } catch (_) {}
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수익 대시보드'), actions: [IconButton(icon: const Icon(Icons.grid_view_rounded), onPressed: () {})]),
      body: Column(
        children: [
          _buildFilterTabs(),
          _buildDateLabel(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? _buildError() : RefreshIndicator(onRefresh: _loadData, child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    const filters = [(_DateFilter.custom, '커스텀'), (_DateFilter.yesterday, '어제'), (_DateFilter.today, '오늘'), (_DateFilter.last7, '최근 7일'), (_DateFilter.thisMonth, '이번 달')];
    return SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), children: filters.map((f) {
      final selected = _filter == f.$1;
      return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
        onTap: () async { if (f.$1 == _DateFilter.custom) { await _pickCustomRange(); } else { setState(() => _filter = f.$1); _loadData(); } },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: selected ? const Color(0xFF00BCD4) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: selected ? null : Border.all(color: Colors.grey.shade800)),
          child: Text(f.$2, style: TextStyle(color: selected ? Colors.black : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ));
    }).toList()));
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4))), child: child!));
    if (picked != null && mounted) { setState(() { _filter = _DateFilter.custom; _customRange = DateRange(start: picked.start, end: picked.end, label: '커스텀'); }); _loadData(); }
  }

  Widget _buildDateLabel() {
    final fmt = DateFormat('dd/MM/yyyy'); final r = _range;
    final label = r.start.isAtSameMomentAs(r.end) ? 'Date: ${fmt.format(r.start)}' : '${fmt.format(r.start)} ~ ${fmt.format(r.end)}';
    return Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)))));
  }

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48), const SizedBox(height: 12),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 16),
    ElevatedButton(onPressed: _loadData, child: const Text('다시 시도')),
  ])));

  Widget _buildContent() {
    final fmt = NumberFormat('#,##0.00', 'ko_KR');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      if (_admobSummary != null) ...[ _hdr('AdMob 합계'), EarningsCard(summary: _admobSummary!), const SizedBox(height: 20)],
      if (_adsenseSummary != null) ...[ _hdr('AdSense 합계'), EarningsCard(summary: _adsenseSummary!), const SizedBox(height: 20)],
      if (_apps.isNotEmpty) ...[ _hdr('${_apps.length}개 앱'), _appList(fmt), const SizedBox(height: 20)],
      if (_adUnits.isNotEmpty) ...[ _hdr('${_adUnits.length}개 광고 단위'), _adUnitList(fmt)],
      if (_admobSummary == null && _adsenseSummary == null && !_loading)
        const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey)))),
    ]);
  }

  Widget _hdr(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const Icon(Icons.pie_chart_rounded, size: 20, color: Color(0xFF00BCD4)),
  ]));

  Widget _appList(NumberFormat fmt) => Container(
    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      ..._apps.take(3).map((app) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.android_rounded, color: Color(0xFF3DDC84), size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Text(app.appName, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₩ ${fmt.format(app.estimatedEarnings)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (app.estimatedEarnings > 0) const Text('↑ 수익 있음', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10)),
        ]),
      ]))),
      if (_apps.length > 3) TextButton(onPressed: () {}, child: const Text('전체 보기', style: TextStyle(color: Color(0xFF00BCD4)))),
    ]),
  );

  Widget _adUnitList(NumberFormat fmt) => Container(
    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
    child: Column(children: _adUnits.take(5).map((u) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.ad_units_rounded, color: Color(0xFF00BCD4), size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(u.adUnitName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
        if (u.adFormat.isNotEmpty) Text(u.adFormat, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ])),
      Text('₩ ${fmt.format(u.estimatedEarnings)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]))).toList()),
  );
}
