class NutrientCodes {
  NutrientCodes._();

  // ── 3대 영양소 ─────────────────────────────────────────
  static const String energy = 'energy';
  static const String carbs = 'carbohydrate';
  static const String protein = 'protein';
  static const String fat = 'fat';

  // ── 추가 영양소 ─────────────────────────────────────────
  static const String sugar = 'sugar';
  static const String fiber = 'dietary_fiber';
  static const String sodium = 'sodium';
  static const String calcium = 'calcium';
  static const String iron = 'iron';
  static const String zinc = 'zinc';
  static const String vitaminA = 'vitamin_a';
  static const String vitaminC = 'vitamin_c';
  static const String vitaminD = 'vitamin_d';

  // ── 표시 순서 ───────────────────────────────────────────
  static const List<String> displayOrder = [
    energy, carbs, protein, fat,
    sugar, fiber, sodium, calcium,
    iron, zinc, vitaminA, vitaminC, vitaminD
  ];

  // ── 한국어 표시명 ────────────────────────────────────────
  static const Map<String, String> labelKr = {
    energy: '열량',
    carbs: '탄수화물',
    protein: '단백질',
    fat: '지방',
    sugar: '당류',
    fiber: '식이섬유',
    sodium: '나트륨',
    calcium: '칼슘',
    iron: '철분',
    zinc: '아연',
    vitaminA: '비타민 A',
    vitaminC: '비타민 C',
    vitaminD: '비타민 D'
  };

  // ── 단위 ────────────────────────────────────────────────
  static const Map<String, String> unit = {
    energy: 'kcal',
    carbs: 'g',
    protein: 'g',
    fat: 'g',
    sugar: 'g',
    fiber: 'g',
    sodium: 'mg',
    calcium: 'mg',
    iron: 'mg',
    zinc: 'mg',
    vitaminA: 'μg',
    vitaminC: 'mg',
    vitaminD: 'μg'
  };
}