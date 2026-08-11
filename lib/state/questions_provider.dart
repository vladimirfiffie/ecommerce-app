import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// A shopper question about a product, with an optional answer.
@immutable
class ProductQuestion {
  const ProductQuestion({
    required this.id,
    required this.productId,
    required this.body,
    required this.askedAt,
    required this.mine,
    this.answer,
    this.answeredBy,
    this.helpfulCount = 0,
  });

  factory ProductQuestion.fromJson(Map<String, dynamic> json) =>
      ProductQuestion(
        id: json['id'] as String,
        productId: json['productId'] as String,
        body: json['body'] as String,
        askedAt: DateTime.parse(json['askedAt'] as String),
        mine: json['mine'] as bool? ?? false,
        answer: json['answer'] as String?,
        answeredBy: json['answeredBy'] as String?,
        helpfulCount: json['helpfulCount'] as int? ?? 0,
      );

  final String id;
  final String productId;
  final String body;
  final DateTime askedAt;

  /// Asked from this device.
  final bool mine;

  final String? answer;
  final String? answeredBy;
  final int helpfulCount;

  bool get isAnswered => answer != null && answer!.isNotEmpty;

  ProductQuestion copyWith({
    String? answer,
    String? answeredBy,
    int? helpfulCount,
  }) => ProductQuestion(
    id: id,
    productId: productId,
    body: body,
    askedAt: askedAt,
    mine: mine,
    answer: answer ?? this.answer,
    answeredBy: answeredBy ?? this.answeredBy,
    helpfulCount: helpfulCount ?? this.helpfulCount,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'productId': productId,
    'body': body,
    'askedAt': askedAt.toIso8601String(),
    'mine': mine,
    if (answer != null) 'answer': answer,
    if (answeredBy != null) 'answeredBy': answeredBy,
    'helpfulCount': helpfulCount,
  };
}

/// Seed questions so a product page isn't an empty Q&A section on first run.
///
/// Deterministic per product id, so the same product always shows the same
/// couple of questions rather than shuffling between visits.
List<ProductQuestion> _seedFor(String productId) {
  const List<(String, String)> pool = <(String, String)>[
    (
      'Does this run true to size?',
      'Yes — most people take their usual size. If you’re between sizes we '
          'suggest sizing up.',
    ),
    (
      'How long does delivery usually take?',
      'Standard is 3–5 business days; express arrives the next business day.',
    ),
    (
      'Is this covered by the return policy?',
      'It is — you have 30 days from delivery to send it back.',
    ),
    (
      'What material is it made from?',
      'The full composition is listed in the product description above.',
    ),
    (
      'Can I get this gift wrapped?',
      'Yes, choose gift wrap at checkout and we’ll add a message card.',
    ),
  ];

  final int seed = productId.hashCode.abs();
  final Random random = Random(seed);
  final int count = 1 + random.nextInt(2);
  final Set<int> picks = <int>{};
  while (picks.length < count) {
    picks.add(random.nextInt(pool.length));
  }

  return <ProductQuestion>[
    for (final int i in picks)
      ProductQuestion(
        id: 'seed-$productId-$i',
        productId: productId,
        body: pool[i].$1,
        askedAt: DateTime.now().subtract(Duration(days: 3 + (seed + i) % 40)),
        mine: false,
        answer: pool[i].$2,
        answeredBy: 'Nova Support',
        helpfulCount: (seed + i * 7) % 24,
      ),
  ];
}

/// Questions asked on this device. Seeded entries live in code, not storage.
class QuestionsNotifier extends Notifier<List<ProductQuestion>> {
  static const String _key = 'questions.mine';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<ProductQuestion> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <ProductQuestion>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <ProductQuestion>[
        for (final Object? q in decoded)
          ProductQuestion.fromJson(q! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <ProductQuestion>[];
    }
  }

  Future<void> _persist(List<ProductQuestion> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((ProductQuestion q) => q.toJson()).toList()),
    );
  }

  /// Files a question. Unanswered until support replies — which, with no
  /// backend, means never; the UI says so rather than faking a response.
  Future<void> ask({required String productId, required String body}) async {
    final String text = body.trim();
    if (text.isEmpty) return;
    await _persist(<ProductQuestion>[
      ProductQuestion(
        id: 'q-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        productId: productId,
        body: text,
        askedAt: DateTime.now(),
        mine: true,
      ),
      ...state,
    ]);
  }

  Future<void> remove(String id) async {
    await _persist(<ProductQuestion>[
      for (final ProductQuestion q in state)
        if (q.id != id) q,
    ]);
  }

  Future<void> clear() async {
    state = const <ProductQuestion>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<QuestionsNotifier, List<ProductQuestion>>
questionsProvider = NotifierProvider<QuestionsNotifier, List<ProductQuestion>>(
  QuestionsNotifier.new,
);

/// Seeded plus asked questions for a product, newest first with this device's
/// own questions pinned to the top.
final ProviderFamily<List<ProductQuestion>, String> productQuestionsProvider =
    Provider.family<List<ProductQuestion>, String>((Ref ref, String productId) {
      final List<ProductQuestion> mine = <ProductQuestion>[
        for (final ProductQuestion q in ref.watch(questionsProvider))
          if (q.productId == productId) q,
      ];
      return <ProductQuestion>[...mine, ..._seedFor(productId)];
    });
