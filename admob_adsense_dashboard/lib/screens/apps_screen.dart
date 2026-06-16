import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/earnings_model.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});
  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppEarnings> _apps = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps()); }

  Future<void> _loadApps() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await context.read<AuthService>().getAccessToken();
      if (token == null) throw Exception('로그인이 필요합니다.');
      final accounts = await AdMobService(token).listAccounts();
      if (accounts.isNotEmpty) _apps = await AdMobService(token).getAppReport(accounts.first.publisherId, DateRange.thisMonth());
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱'), actions: [IconButton(icon: const Icon(Icons.grid_view_rounded), onPressed: () {})]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
          : _apps.isEmpty ? const Center(child: Text('연결된 앱이 없습니다.', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(onRefresh: _loadApps, child: ListView.builder(
              padding: const EdgeInsets.all(16), itemCount: _apps.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.android_rounded, color: Color(0xFF3DDC84))),
                  title: Text(_apps[i].appName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_apps[i].packageName != null) Text(_apps[i].packageName!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    const Text('ANDROID', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                  trailing: const Icon(Icons.link_rounded, color: Color(0xFF00BCD4)),
                  isThreeLine: _apps[i].packageName != null,
                ),
              ),
            )),
    );
  }
}
