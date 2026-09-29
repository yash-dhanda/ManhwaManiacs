/// A chapter as the mark-read helpers see it.
typedef ChapterRef = ({String key, double? number, bool completed});

/// Every not-yet-completed chapter numbered at or below [number]
/// (chapters without a number are excluded).
List<ChapterRef> chaptersUpTo(List<ChapterRef> chapters, double number) => [
      for (final c in chapters)
        if (c.number != null && c.number! <= number && !c.completed) c,
    ];

/// The keys an Undo deletes: only those that were not completed before.
List<String> undoMarkReadKeys(Set<String> previouslyCompleted, List<String> marked) => [
      for (final k in marked)
        if (!previouslyCompleted.contains(k)) k,
    ];

/// Splits [items] into chunks of [size] (the API takes 200 rows at a time).
List<List<T>> chunked<T>(List<T> items, {int size = 200}) => [
      for (var i = 0; i < items.length; i += size)
        items.sublist(i, i + size > items.length ? items.length : i + size),
    ];
