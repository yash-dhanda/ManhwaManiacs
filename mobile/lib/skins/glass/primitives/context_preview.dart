/// What a context menu lifts (glass 7.8): the raised copy of the pressed object scales by its kind.
enum GlassPreviewKind { poster, row, image }

/// The lift scale of a preview: poster 1.12, row 1.02, image 1.0.
double glassPreviewScale(GlassPreviewKind kind) => switch (kind) {
      GlassPreviewKind.poster => 1.12,
      GlassPreviewKind.row => 1.02,
      GlassPreviewKind.image => 1.0,
    };
