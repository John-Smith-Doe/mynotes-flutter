// login excpetions
class UserNotFoundAuthException implements Exception {}

class WrontPasswordAuthException implements Exception {}

// register excpetions
class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

// generic exceptions

class GenericAuthExcepiton implements Exception {}

class UserNotLoggedInAuthException implements Exception {}
