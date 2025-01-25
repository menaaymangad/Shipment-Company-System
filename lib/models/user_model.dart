class User {
  final int? id;
  final String userName;
  final String branchName;
  final String authorization;
  final bool allowLogin;
  final String password;

  User({
    this.id,
    required this.userName,
    required this.branchName,
    required this.authorization,
    required this.allowLogin,
    required this.password,
  });

  // Add the copyWith method
  User copyWith({
    int? id,
    String? userName,
    String? branchName,
    String? authorization,
    bool? allowLogin,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      branchName: branchName ?? this.branchName,
      authorization: authorization ?? this.authorization,
      allowLogin: allowLogin ?? this.allowLogin,
      password: password ?? this.password,
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      userName: map['userName'],
      branchName: map['branchName'],
      authorization: map['authorization'] ?? '',
      allowLogin: map['allowLogin'] == 1 || map['allowLogin'] == true,
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'branchName': branchName,
      'authorization': authorization,
      'allowLogin': allowLogin ? 1 : 0,
      'password': password,
    };
  }
}
