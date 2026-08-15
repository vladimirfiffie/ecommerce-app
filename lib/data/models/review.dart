import 'package:flutter/foundation.dart';

/// A customer review shown on the product detail page.
@immutable
class Review {
  const Review({
    required this.author,
    required this.rating,
    required this.body,
    required this.daysAgo,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    author: json['author'] as String,
    rating: (json['rating'] as num).toDouble(),
    body: json['body'] as String,
    daysAgo: json['daysAgo'] as int? ?? 0,
  );

  final String author;
  final double rating;
  final String body;
  final int daysAgo;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'author': author,
    'rating': rating,
    'body': body,
    'daysAgo': daysAgo,
  };

  String get initials => author.isEmpty ? '?' : author[0].toUpperCase();

  String get timeAgo {
    if (daysAgo <= 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 30) return '$daysAgo days ago';
    final int months = (daysAgo / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }
}
