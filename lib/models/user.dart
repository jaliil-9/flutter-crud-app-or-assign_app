import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  final String uid;
  final String phoneNumber;
  final DateTime? lastLogin;

  const User({required this.uid, required this.phoneNumber, this.lastLogin});

  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      lastLogin: firebaseUser.metadata.lastSignInTime,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      phoneNumber: json['phoneNumber'] as String,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({String? uid, String? phoneNumber, DateTime? lastLogin}) {
    return User(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! User) return false;

    return other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode => Object.hash(uid, phoneNumber, lastLogin);

  @override
  String toString() {
    return 'User(uid: $uid, phoneNumber: $phoneNumber, lastLogin: $lastLogin)';
  }
}
