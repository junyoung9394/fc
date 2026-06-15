import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/earnings_model.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AdMobAccount? _account;
  String _currency = 'KRW';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccount());
  }

  Future<void> _loadAccount() async {
    try {
      final token = await context.read<AuthService>().getAccessToken();
      if (token == null) return;
      final accounts = await AdMobService(token).listAccounts();
      if (accounts.isNotEmpty && mounted) {
        setState(() {
          _account = accounts.first;
          _currency = accounts.first.currencyCode;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('사용자 정보'),
                const SizedBox(height: 16),
                if (user?.photoUrl != null)
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user!.photoUrl!),
                    ),
                  ),
                const SizedBox(height: 16),
                _infoTile(Icons.label_rounded, '이름',
                    user?.displayName ?? '-', Colors.orange),
                const SizedBox(height: 8),
                _infoTile(Icons.language_rounded, 'Publisher ID',
                    _account?.publisherId ?? '-', Colors.blue),
                const SizedBox(height: 8),
                _currencyTile(),
                const SizedBox(height: 8),
                _infoTile(
                    Icons.access_time_rounded,
                    '시간대',
                    _account?.reportingTimeZone ?? 'Asia/Seoul',
                    Colors.green),
                const SizedBox(height: 32),
                _sectionTitle('계정'),
                const SizedBox(height: 12),
                _logoutTile(context),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _infoTile(
      IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyTile() {
    const currencies = ['KRW', 'USD', 'EUR', 'JPY'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded,
              color: Colors.green, size: 20),
          const SizedBox(width: 12),
          const Text('통화', style: TextStyle(color: Colors.grey)),
          const Spacer(),
          DropdownButton<String>(
            value: _currency,
            dropdownColor: const Color(0xFF1A1A1A),
            underline: const SizedBox(),
            items: currencies
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'KRW'),
          ),
        ],
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.red),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () => context.read<AuthService>().signOut(),
      ),
    );
  }
}
