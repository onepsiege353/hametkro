/// Catalogue des catégories de vente Hametkro.
class Category {
  final String id;
  final String name;
  final String emoji;
  final bool fashion; // true => catégorie "mode / friperie" centrale

  const Category(this.id, this.name, this.emoji, {this.fashion = false});

  static const List<Category> all = [
    Category('fashion', "Mode & Friperie", '👗', fashion: true),
    Category('phone', "Téléphones", '📱'),
    Category('computer', "Ordinateurs", '💻'),
    Category('cars', "Voitures & Moto", '🚗'),
    Category('furniture', "Meubles & Maison", '🛋️'),
    Category('electronics', "Électronique", '🎧'),
    Category('appliances', "Électroménager", '🧺'),
    Category('beauty', "Beauté & Bien-être", '💄'),
    Category('sports', "Sport & Loisirs", '⚽'),
    Category('books', "Livres & Études", '📚'),
    Category('toys', "Jeux & Enfants", '🧸'),
    Category('other', "Autres", '📦'),
  ];

  static Category? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// États d'un article d'occasion.
const List<String> kConditions = [
  'Neuf',
  'Comme neuf',
  'Très bon état',
  'Bon état',
  'Correct',
  'À réparer',
];
