import 'dart:math';

import 'package:faker/faker.dart';
import 'package:alive_shot/screens/models/models.dart';

class Post {
  final User owner;
  final String? title;
  final String? description;
  final int? categoryId;
  final String postImage;
  final String? contentType;
  List<Comment> comments;
  final String? date;
  int likeCount;
  int saveCount;
  bool isLiked;
  bool isSaved;

  Post({
    required this.owner,
    this.title,
    this.description,
    this.categoryId,
    required this.postImage,
    required this.contentType,
    required this.comments,
    this.date,
    required this.likeCount,
    required this.saveCount,
    this.isLiked = false,
    this.isSaved = false,
  });

  Post copyWith({
    User? owner,
    String? title,
    String? description,
    int? categoryId,
    String? postImage,
    List<Comment>? comments, // Permitir actualizar comments
    String? date,
    int? likeCount,
    int? saveCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      owner: owner ?? this.owner,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      postImage: postImage ?? this.postImage,
      contentType: contentType,
      comments: comments ?? this.comments, // Actualizar la lista
      date: date ?? this.date,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static final List<Post> dummyPosts = List.generate(30, (index) {
    final Faker faker = Faker();
    return Post(
      owner:
          User.dummyUsers[index > 15
              ? 0
              : Random().nextInt(User.dummyUsers.length - 1)],
      title: faker.lorem.words(3).join(' '),
      description: faker.lorem.sentences(2).join(' '),
      categoryId: Random().nextInt(6) + 1,
      postImage: faker.image.loremPicsum(
        random: Random().nextInt(30),
        height: 640,
        width: 640,
      ),
      contentType: 'image/jpeg',
      comments: Comment.generateDummyComments(),
      date: faker.date.dateTime(minYear: 2020, maxYear: 2024).toIso8601String(),
      likeCount: Random().nextInt(1000),
      saveCount: Random().nextInt(1000),
    );
  });
}
