//@dart=2.12

enum AccountStorageKeys {
  latestToken,
  latestTokenDate,
  membershipData
}

extension StorageKeyPathsExtension on AccountStorageKeys {
  String get path {
    String name = this.toString().split(".")[1];
    return name;
  }
}