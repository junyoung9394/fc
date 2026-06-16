import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earnings_model.dart';

class EarningsCard extends StatefulWidget {
  final EarningsSummary summary;
  const EarningsCard({super.key, required this.summary});
  @override
  State<EarningsCard> createState() => _EarningsCardState();
}

class _EarningsCardState extends State<EarningsCard> {
  int _sel = 0;
  static const _labels = ['예상 수익', 'eCPM', '노출수', '클릭수'];

  String _val(int i) {
    final f = NumberFormat('#,##0.000', 'ko_KR');
    final fi = NumberFormat('#,##0', 'ko_KR');
    switch (i) {
      case 0: return '₩ ${f.format(widget.summary.estimatedEarnings)}';
      case 1: return '₩ ${f.format(widget.summary.ecpm)}';
      case 2: return fi.format(widget.summary.impressions);
      case 3: return fi.format(widget.summary.clicks);
      default: return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: List.generate(_labels.length, (i) {
            final selected = _sel == i;
            return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
              onTap: () => setState(() => _sel = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: selected ? const Color(0xFF00BCD4) : const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)),
                child: Text(_labels[i], style: TextStyle(color: selected ? Colors.black : const Color(0xFF00BCD4), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ));
          })),
        ),
        const Divider(color: Color(0xFF2A2A2A), height: 1),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_val(_sel), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          if (_sel == 0 && widget.summary.earningsChange != null)
            Row(children: [
              Text('₩ ${NumberFormat("+#,##0.0;-#,##0.0", "ko_KR").format(widget.summary.earningsChange!)} (${NumberFormat("+#,##0.0;-#,##0.0", "ko_KR").format(widget.summary.earningsChangePercent!)}%)',
                style: TextStyle(color: widget.summary.earningsChange! >= 0 ? const Color(0xFF4CAF50) : Colors.red, fontSize: 13)),
              Icon(widget.summary.earningsChange! >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: widget.summary.earningsChange! >= 0 ? const Color(0xFF4CAF50) : Colors.red, size: 14),
            ]),
        ])),
      ]),
    );
  }
}
