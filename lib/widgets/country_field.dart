import 'package:flutter/material.dart';

import '../services/countries.dart';

/// Sélecteur de pays pour le marché Hametkro.
class CountryField extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<(String, String)> onChanged;
  const CountryField(
      {super.key, required this.selectedCode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sel = Countries.byCode(selectedCode ?? 'CI');
    final selName = sel?.$2 ?? "Côte d'Ivoire";
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E7E3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.public, color: Color(0xFF009A44)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Marché',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey, height: 1)),
                  const SizedBox(height: 2),
                  Text(selName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisis ton pays (marché local)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Countries.all.length,
                itemBuilder: (_, i) {
                  final c = Countries.all[i];
                  final selected = c.$1 == selectedCode;
                  return ListTile(
                    leading: Text(_flag(c.$1),
                        style: const TextStyle(fontSize: 22)),
                    title: Text(c.$2,
                        style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF009A44)
                                : Colors.black)),
                    trailing: selected
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF009A44))
                        : null,
                    onTap: () {
                      onChanged(c);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // petit émoji drapeau approximatif par code (fallback globe).
  static String _flag(String code) {
    const map = {
      'CI': '🇨🇮', 'SN': '🇸🇳', 'CM': '🇨🇲', 'ML': '🇲🇱', 'BF': '🇧🇫',
      'TG': '🇹🇬', 'BJ': '🇧🇯', 'GN': '🇬🇳', 'NE': '🇳🇪', 'GA': '🇬🇦',
      'CG': '🇨🇬', 'CD': '🇨🇩', 'NG': '🇳🇬', 'GH': '🇬🇭', 'KE': '🇰🇪',
      'ZA': '🇿🇦', 'MA': '🇲🇦', 'DZ': '🇩🇿', 'TN': '🇹🇳', 'EG': '🇪🇬',
      'FR': '🇫🇷', 'CA': '🇨🇦', 'US': '🇺🇸', 'BE': '🇧🇪', 'CH': '🇨🇭',
    };
    return map[code] ?? '🌍';
  }
}
