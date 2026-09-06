/// Liste des pays du marché Hametkro.
/// L'utilisateur choisit son pays ; il voit ensuite uniquement les annonces
/// publiées dans ce pays. Liste extensible au monde entier.
class Countries {
  static const List<(String, String)> all = [
    ("CI", "Côte d'Ivoire"),
    ("SN", "Sénégal"),
    ("CM", "Cameroun"),
    ("ML", "Mali"),
    ("BF", "Burkina Faso"),
    ("TG", "Togo"),
    ("BJ", "Bénin"),
    ("GN", "Guinée"),
    ("NE", "Niger"),
    ("GA", "Gabon"),
    ("CG", "Congo"),
    ("CD", "RDC"),
    ("NG", "Nigeria"),
    ("GH", "Ghana"),
    ("KE", "Kenya"),
    ("ZA", "Afrique du Sud"),
    ("MA", "Maroc"),
    ("DZ", "Algérie"),
    ("TN", "Tunisie"),
    ("EG", "Égypte"),
    ("FR", "France"),
    ("CA", "Canada"),
    ("US", "États-Unis"),
    ("BE", "Belgique"),
    ("CH", "Suisse"),
  ];

  static (String, String)? byCode(String code) {
    for (final c in all) {
      if (c.$1 == code) return c;
    }
    return null;
  }
}
