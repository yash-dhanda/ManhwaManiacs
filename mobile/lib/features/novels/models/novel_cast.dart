/// Who speaks in a chapter, and in whose voice.
///
/// Only what decides how a line SOUNDS lives here: a name, a gender, a voice
/// id, and the roster to choose from. `frontend/AGENTS.md` records that
/// character/world/timeline extraction was permanently abandoned and must
/// never come back, and a "cast" is one field away from being exactly that. A
/// description, a relationship, a first appearance would all be the abandoned
/// thing wearing a different hat.
library;

/// One character who can be given a voice.
class NovelCastMember {
  const NovelCastMember({
    required this.name,
    required this.gender,
    required this.voiceId,
    this.locked = false,
    this.lineCount,
  });

  factory NovelCastMember.fromJson(Map<String, dynamic> json) {
    return NovelCastMember(
      name: (json['name'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? 'unknown',
      voiceId: json['voice_id'] as String?,
      locked: json['locked'] == true,
      lineCount: (json['line_count'] as num?)?.toInt(),
    );
  }

  /// Set by hand (the owner's correction). Absent on a server that does not say, which reads as
  /// "not locked".
  final bool locked;

  /// Spoken lines in the series when the server reports them; the sheet falls back to counting
  /// the chapter's own spans.
  final int? lineCount;

  final String name;

  /// From accumulated pronoun counts, never from the name — web-novel casts
  /// are transliterated and a guess is wrong on every line that character
  /// speaks. `unknown` is a real value that routes to the narrator.
  final String gender;

  /// The voice pinned for this character, or null for none pinned — in
  /// which case the renderer assigns one automatically when a chapter is
  /// made. Null is NOT "reads as narrator"; the clients label it "Automatic".
  final String? voiceId;
}

/// One voice a character can be given.
class NovelVoice {
  const NovelVoice({
    required this.voiceId,
    required this.name,
    required this.character,
    required this.gender,
    required this.pitchHz,
    required this.seconds,
    this.expressiveness = 0,
    this.license = '',
    this.attribution = '',
    this.transcript = '',
  });

  factory NovelVoice.fromJson(Map<String, dynamic> json) {
    final id = (json['voice_id'] as String?) ?? '';
    return NovelVoice(
      voiceId: id,
      // A person cannot choose between libritts-2803 and libritts-251; they
      // can choose between Atlas and Lucian.
      name: switch ((json['name'] as String?)?.trim()) {
        final String n when n.isNotEmpty => n,
        _ => id,
      },
      character: (json['character'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? 'unknown',
      pitchHz: (json['pitch_hz'] as num?)?.toDouble() ?? 0,
      seconds: (json['seconds'] as num?)?.toDouble() ?? 0,
      expressiveness: (json['expressiveness'] as num?)?.toDouble() ?? 0,
      license: (json['license'] as String?) ?? '',
      attribution: (json['attribution'] as String?) ?? '',
      transcript: (json['transcript'] as String?) ?? '',
    );
  }

  final String voiceId;

  /// What the picker calls it, and what the sample hears itself called.
  final String name;

  /// Two words on how it reads — "deep, steady".
  final String character;
  final String gender;

  /// The one number that orders the list the way people ask for it.
  final double pitchHz;

  /// How long the introduction runs.
  final double seconds;

  /// A raw pitch spread with no fixed range: rank it among the loaded voices.
  final double expressiveness;
  final String license, attribution;

  /// What the sample says (shown under the row while it plays).
  final String transcript;
}

/// A chapter's attribution: who speaks, and the voices in play.
class NovelAttribution {
  const NovelAttribution({
    required this.attributed,
    required this.narrator,
    required this.narratorVoiceId,
    required this.cast,
    this.textFingerprint,
    this.spans = const <NovelSpeakerSpan>[],
  });

  factory NovelAttribution.fromJson(Map<String, dynamic> json) {
    final raw = json['cast'];
    return NovelAttribution(
      attributed: json['attributed'] == true,
      narrator: json['narrator'] as String?,
      narratorVoiceId: json['narrator_voice_id'] as String?,
      cast: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(NovelCastMember.fromJson)
              .where((member) => member.name.isNotEmpty)
              .toList(growable: false)
          : const <NovelCastMember>[],
      textFingerprint: json['text_fingerprint'] as String?,
      spans: json['spans'] is List
          ? (json['spans'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NovelSpeakerSpan.fromJson)
              .toList(growable: false)
          : const <NovelSpeakerSpan>[],
    );
  }

  /// SHA-256 of the paragraphs the offsets were computed against (`chapter_fingerprint` on the
  /// server); tints are only trusted when it matches the text on screen.
  final String? textFingerprint;

  /// Quoted runs, `p` = paragraph index, offsets in Unicode code points.
  final List<NovelSpeakerSpan> spans;

  /// An unattributed chapter is the ORDINARY case, not an error: almost
  /// nothing in the library has been through the pass.
  static const NovelAttribution none = NovelAttribution(
    attributed: false,
    narrator: null,
    narratorVoiceId: null,
    cast: <NovelCastMember>[],
  );

  final bool attributed;

  /// Who narrates this chapter, when it is known.
  final String? narrator;

  /// The series' pinned narration voice, or null to use the derived default.
  final String? narratorVoiceId;

  final List<NovelCastMember> cast;
}


/// One attributed stretch of speech (`GET /novels/attribution` `spans[]`).
class NovelSpeakerSpan {
  const NovelSpeakerSpan({required this.paragraph, required this.start, required this.end, required this.head, required this.speaker});

  factory NovelSpeakerSpan.fromJson(Map<String, dynamic> json) => NovelSpeakerSpan(
        paragraph: (json['p'] as num?)?.toInt() ?? -1,
        start: (json['s'] as num?)?.toInt() ?? 0,
        end: (json['e'] as num?)?.toInt() ?? 0,
        head: (json['head'] as String?) ?? '',
        speaker: json['speaker'] as String?,
      );

  final int paragraph, start, end;

  /// The first characters of the attributed text, proving the offsets.
  final String head;

  /// The speaker's name, or null when the line stays with the narrator.
  final String? speaker;
}

/// What came of asking for chapters to be narrated.
///
/// Every chapter is answered for. A partial result is the ordinary outcome —
/// asking for a whole book normally finds some of it already done — so this
/// carries both halves rather than being a success/failure.
class NovelAudioRequest {
  const NovelAudioRequest({required this.queued, required this.skipped});

  factory NovelAudioRequest.fromJson(Map<String, dynamic> json) {
    List<String> keys(String field) {
      final raw = json[field];
      return raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map((e) => (e['chapter_key'] as String?) ?? '')
                .where((k) => k.isNotEmpty)
                .toList(growable: false)
          : const <String>[];
    }

    final raw = json['skipped'];
    return NovelAudioRequest(
      queued: keys('queued'),
      skipped: raw is List
          ? {
              for (final e in raw.whereType<Map<String, dynamic>>())
                if ((e['chapter_key'] as String?)?.isNotEmpty ?? false)
                  e['chapter_key'] as String:
                      (e['reason'] as String?) ?? 'skipped',
            }
          : const <String, String>{},
    );
  }

  final List<String> queued;

  /// chapter key -> why. `chapter_not_cached` is the one a reader can act on:
  /// download the text first.
  final Map<String, String> skipped;
}

/// One render, and where it got to.
class NovelAudioJob {
  const NovelAudioJob({
    required this.jobId,
    required this.chapterKey,
    required this.status,
    required this.progress,
    required this.errorCode,
    this.chapterNumber,
    this.errorDetail,
    this.createdAt,
  });

  factory NovelAudioJob.fromJson(Map<String, dynamic> json) {
    return NovelAudioJob(
      jobId: (json['job_id'] as String?) ?? '',
      chapterKey: (json['chapter_key'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'queued',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      errorCode: json['error_code'] as String?,
      chapterNumber: (json['chapter_number'] as num?)?.toDouble(),
      errorDetail: json['error_detail'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    );
  }

  final double? chapterNumber;
  final String? errorDetail;

  /// When the job was created, when the server says (`RE-VOICING` compares it to a cast change).
  final DateTime? createdAt;

  final String jobId;
  final String chapterKey;

  /// queued | planning | rendering | done | failed | cancelled
  final String status;

  /// 0..1, and 0 until the render box has reported a segment.
  final double progress;
  final String? errorCode;

  bool get isActive => isWaiting || isRunning;

  /// Asked for, and no render box has picked it up yet. Not "in progress":
  /// with no worker free — or none configured — it can sit here for a long
  /// time, and calling that progress is how a label ends up lying for days.
  bool get isWaiting => status == 'queued';

  /// A render box has it and is working on it.
  bool get isRunning => status == 'planning' || status == 'rendering';
}
