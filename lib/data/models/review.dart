import 'package:flutter/foundation.dart';

/// A customer review shown on the product detail page.
@immutable
class Review {
  const Review({
    required this.author,
    required this.rating,
    required this.body,
    required this.daysAgo,
    this.verified = false,
    this.tags = const <String>[],
    this.photos = const <String>[],
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    author: json['author'] as String,
    rating: (json['rating'] as num).toDouble(),
    body: json['body'] as String,
    daysAgo: json['daysAgo'] as int? ?? 0,
    verified: json['verified'] as bool? ?? false,
    tags: <String>[
      for (final Object? t in json['tags'] as List<dynamic>? ?? <dynamic>[])
        t as String,
    ],
    photos: <String>[
      for (final Object? p in json['photos'] as List<dynamic>? ?? <dynamic>[])
        p as String,
    ],
  );

  final String author;
  final double rating;
  final String body;
  final int daysAgo;

  /// Written by someone who actually bought it. The shop only accepts
  /// reviews from buyers, so this is a fact about the review rather than a
  /// badge handed out.
  final bool verified;

  /// What the review is about — Fit, Quality, Value, Delivery. Read off the
  /// words the reviewer used rather than asked for separately.
  final List<String> tags;

  /// Photos attached to the review.
  final List<String> photos;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'author': author,
    'rating': rating,
    'body': body,
    'daysAgo': daysAgo,
    if (verified) 'verified': verified,
    if (tags.isNotEmpty) 'tags': tags,
    if (photos.isNotEmpty) 'photos': photos,
  };

  String get initials => author.isEmpty ? '?' : author[0].toUpperCase();

  /// The subjects a review can be filed under.
  ///
  /// Deliberately few: a filter with twenty options is a list, not a filter.
  static const List<String> allTags = <String>[
    'Fit',
    'Quality',
    'Value',
    'Delivery',
  ];

  /// Reads the subjects out of what the reviewer wrote.
  ///
  /// Nothing invented — a review only carries a tag if it used one of the
  /// words behind it, which is why plenty of them carry none at all.
  static List<String> tagsIn(String text) {
    final String lower = text.toLowerCase();
    bool mentions(List<String> words) =>
        words.any((String w) => lower.contains(w));

    return <String>[
      if (mentions(<String>['fit', 'size', 'sizing', 'tight', 'loose', 'snug']))
        'Fit',
      if (mentions(<String>[
        'quality',
        'material',
        'fabric',
        'sturdy',
        'flimsy',
        'cheap feel',
        'well made',
        'build',
      ]))
        'Quality',
      if (mentions(<String>['value', 'price', 'worth', 'bargain', 'expensive']))
        'Value',
      if (mentions(<String>[
        'delivery',
        'shipping',
        'arrived',
        'packaging',
        'packaged',
        'fast',
      ]))
        'Delivery',
    ];
  }

  String get timeAgo {
    if (daysAgo <= 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 30) return '$daysAgo days ago';
    final int months = (daysAgo / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }
}
