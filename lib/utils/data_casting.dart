// lib/utils/data_casting.dart

/// Recursively casts a Map or List from Firebase (which may contain
/// generic Object types) into a structure with String keys and dynamic values,
/// which is required by fromMap constructors.
dynamic deepCast(dynamic value) {
  if (value is Map) {
    // Casts Map<Object?, Object?> to Map<String, dynamic>
    return value.map((key, val) => MapEntry(key.toString(), deepCast(val)));
  }
  if (value is List) {
    // Recursively casts each element in the list
    return value.map((e) => deepCast(e)).toList();
  }
  // Return primitive types as is
  return value;
}