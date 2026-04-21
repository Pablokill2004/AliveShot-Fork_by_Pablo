import 'dart:math';

import 'package:faker/faker.dart';

class User {
  String firebaseUid;
  String profileImage;
  String bannerImage;
  String username;
  String fullname;
  String bio;
  int followersCount;
  int followingCount;
  bool isMe;

  String email;
  String name;
  String lastname;
  String birthday;
  String gender;
  String title;
  String address;
  String phone;

  //compete page
  int chlallengesCreated;
  int challengesWon;
  int streak;

  User({
    required this.firebaseUid,
    required this.profileImage,
    required this.bannerImage,
    required this.username,
    required this.fullname,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.email,
    required this.name,
    required this.lastname,
    required this.birthday,
    required this.gender,
    required this.title,
    required this.address,
    required this.phone,
    required this.chlallengesCreated,
    required this.challengesWon,
    required this.streak,
    this.isMe = false,
  });

  // Convertir un Map a un objeto User
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      firebaseUid: data['firebase_uid'] ?? '',
      profileImage: data['image'] ?? '',
      bannerImage: data['image_header'] ?? '',
      username: data['username'] ?? '',
      fullname: '${data['name'] ?? ''} ${data['last_name'] ?? ''}',
      bio: data['bio'] ?? '',
      followersCount: data['followers'] ?? 0,
      followingCount: data['following'] ?? 0,
      isMe: false,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      lastname: data['last_name'] ?? '',
      birthday: data['birthday'] ?? '',
      gender: data['gender'] ?? '',
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      chlallengesCreated: data['challenges_created'] ?? 0,
      challengesWon: data['challenges_won'] ?? 0,
      streak: data['streak'] ?? 0,
    );
  }

  static final List<User> dummyUsers = List.generate(5, (index) {
    final Faker faker = Faker();
    return User(
      firebaseUid: faker.guid.guid(), // Generar un GUID como placeholder
      isMe: index == 0,
      profileImage: faker.image.loremPicsum(
        random: Random().nextInt(5),
        width: 640,
        height: 640,
      ),
      bannerImage: faker.image.loremPicsum(
        random: Random().nextInt(5),
        width: 640,
        height: 480,
      ),
      email: faker.internet.email(),
      name: "",
      lastname: "",
      birthday: "",
      gender: "",
      title: "",
      address: "",
      phone: "",
      username: faker.internet.userName(),
      fullname: faker.person.name(),
      bio: faker.lorem.sentence(),
      followersCount: Random().nextInt(1000),
      followingCount: Random().nextInt(1000),
      chlallengesCreated: 0,
      challengesWon: 0,
      streak: 0,
    );
  });
}
