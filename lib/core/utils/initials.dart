String getInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';

  final trimmed = name.trim();
  return trimmed.length >= 2
      ? trimmed.substring(0, 2).toUpperCase()
      : trimmed.substring(0, 1).toUpperCase();
}
