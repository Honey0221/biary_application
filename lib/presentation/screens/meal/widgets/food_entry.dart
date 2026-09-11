import 'package:flutter/material.dart';

import '../../../../data/models/food_search_result.dart';

class FoodEntry {
  FoodSearchResult? selectedFood;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  String? reactionType; // 'good' | 'normal' | 'bad' | null

  FoodEntry({String name = '', String amount = '', this.reactionType})
      : nameCtrl = TextEditingController(text: name),
        amountCtrl = TextEditingController(text: amount);

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}