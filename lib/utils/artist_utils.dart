final RegExp _artistNameSplitPattern = RegExp(
  r'\s*(?:,|&|\bx\b)\s*|\s+\b(?:feat(?:uring)?|ft|with)\.?(?=\s|$)\s*',
  caseSensitive: false,
);

List<String> splitArtistNames(String rawArtists) {
  final raw = rawArtists.trim();
  if (raw.isEmpty) return const [];

  return raw
      .split(_artistNameSplitPattern)
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}
