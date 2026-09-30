/// A member of the Circle as `GET /circle/series` and `/circle/reactions` name them.
class CircleMemberRef {
  const CircleMemberRef({required this.profileId, required this.name, this.avatarKey, this.username});

  final int profileId;
  final String name;
  final String? avatarKey, username;

  factory CircleMemberRef.fromJson(Map<String, dynamic> j) => CircleMemberRef(
        profileId: (j['profile_id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        avatarKey: j['avatar_key'] as String?,
        username: j['username'] as String?,
      );
}

/// How far a member has read of a series (`readers[]` of `GET /circle/series`).
class CircleReader {
  const CircleReader({required this.member, required this.chapterKey, this.chapterNumber});

  final CircleMemberRef member;
  final String chapterKey;
  final double? chapterNumber;

  factory CircleReader.fromJson(Map<String, dynamic> j) => CircleReader(
        member: CircleMemberRef.fromJson(Map<String, dynamic>.from(j['profile'] as Map? ?? const {})),
        chapterKey: j['chapter_key'] as String? ?? '',
        chapterNumber: (j['chapter_number'] as num?)?.toDouble(),
      );
}

/// The reactions on one chapter (`chapters[]` of `GET /circle/reactions`). [sealed] is the
/// server's half of the spoiler guard: true until the viewer has completed the chapter.
class CircleChapterReactions {
  const CircleChapterReactions({required this.chapterKey, this.chapterNumber, this.by = const [], this.sealed = true});

  final String chapterKey;
  final double? chapterNumber;
  final List<({CircleMemberRef member, String kind})> by;
  final bool sealed;

  factory CircleChapterReactions.fromJson(Map<String, dynamic> j) => CircleChapterReactions(
        chapterKey: j['chapter_key'] as String? ?? '',
        chapterNumber: (j['chapter_number'] as num?)?.toDouble(),
        sealed: j['sealed'] as bool? ?? true,
        by: [
          for (final r in (j['by'] as List? ?? const []))
            if (r is Map) (member: CircleMemberRef.fromJson(Map<String, dynamic>.from(r)), kind: r['kind'] as String? ?? ''),
        ],
      );
}

/// What the reader's CIRCLE tab needs for one series.
class CircleSeriesData {
  const CircleSeriesData({this.readers = const [], this.chapters = const []});

  final List<CircleReader> readers;
  final List<CircleChapterReactions> chapters;
}
