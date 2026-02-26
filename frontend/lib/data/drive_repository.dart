import '../models/drive_record.dart';

class DriveRepository {
  static List<DriveRecord> getMockData() {
    return [
      DriveRecord(
        date: DateTime(2026, 2, 18),
        score: 6,
        duration: const Duration(minutes: 48),
      ),
      DriveRecord(
        date: DateTime(2026, 2, 20),
        score: 85,
        duration: const Duration(minutes: 36),
      ),
      DriveRecord(
        date: DateTime(2026, 2, 21),
        score: 72,
        duration: const Duration(minutes: 52),
      ),
    ];
  }
}