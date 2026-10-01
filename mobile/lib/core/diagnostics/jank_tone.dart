/// The jank tone of Diagnostics (glass 8.25.12): good below 5 %, warn below 15 %, bad otherwise.
enum JankTone { good, warn, bad }

JankTone jankTone(double percent) => percent < 5 ? JankTone.good : (percent < 15 ? JankTone.warn : JankTone.bad);
