class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => 'BackupException: $message';
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => 'SyncException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
  @override
  String toString() => 'EncryptionException: $message';
}
