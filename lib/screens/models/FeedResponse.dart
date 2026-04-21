class FeedResponse {
  final int page;
  final int count;
  final List<Map<String, dynamic>> posts;

  FeedResponse({required this.page, required this.count, required this.posts});

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      page: json['page'],
      count: json['count'],
      posts: List<Map<String, dynamic>>.from(json['posts']),
    );
  }
}
