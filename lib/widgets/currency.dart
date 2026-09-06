/// Formate un prix en FCFA avec séparateurs de milliers.
String formatPrice(double amount) {
  final n = amount.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final remaining = s.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buf.write(' ');
  }
  return buf.toString();
}

// Estimation du CO2 évité par catégorie (kg eq. CO2) — ordres de grandeur.
const Map<String, double> _co2ByCategory = {
  'fashion': 5.0,
  'phone': 48.0,
  'computer': 200.0,
  'cars': 3500.0,
  'furniture': 150.0,
  'electronics': 30.0,
  'appliances': 60.0,
  'beauty': 3.0,
  'sports': 25.0,
  'books': 2.0,
  'toys': 12.0,
  'other': 10.0,
};

/// Estimation raisonnable des kg de CO2 évités par la réutilisation.
double estimateCo2Saved(String categoryId) =>
    _co2ByCategory[categoryId] ?? 10.0;
