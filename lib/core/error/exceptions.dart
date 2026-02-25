class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
}

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
}

// Add more for auth, db, etc.
