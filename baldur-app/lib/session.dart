class Session {
  final int duration; // Session length in seconds
  final int debrisCount;
  final String notes; // Optional session notes

  Session({
    required this.duration,
    required this.debrisCount,
    this.notes = "",
  });

  String displayTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return "${remainingSeconds.toString()} seconds";
    }
    else if (hours == 0) {
      return "${minutes.toString().padLeft(2, '0')} minutes ${remainingSeconds.toString()
          .padLeft(2, '0')} secs";
    }
    return "${hours.toString().padLeft(2, '0')} hours ${minutes.toString().padLeft(2, '0')} mins ${remainingSeconds.toString()
        .padLeft(2, '0')} secs";
  }
}