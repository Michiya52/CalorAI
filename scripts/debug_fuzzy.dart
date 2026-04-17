import 'package:fuzzywuzzy/fuzzywuzzy.dart';

void main() {
  final query = "watermelon";
  final targets = [
    "Watermelon, raw",
    "Tuna chunks in water",
    "Beef Teppanyaki",
    "Watermelon juice",
  ];

  print("Query: $query");
  for (final target in targets) {
    final lowerTarget = target.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    final ratioScore = ratio(lowerQuery, lowerTarget);
    final partialScore = partialRatio(lowerQuery, lowerTarget);
    final tokenSetScore = tokenSetRatio(lowerQuery, lowerTarget);
    final weightedScore = weightedRatio(lowerQuery, lowerTarget);
    
    print("\nTarget: $target");
    print("  Ratio: $ratioScore");
    print("  Partial: $partialScore");
    print("  TokenSet: $tokenSetScore");
    print("  Weighted: $weightedScore");
  }
}
