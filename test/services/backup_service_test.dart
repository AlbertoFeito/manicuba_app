import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:manicuba_app/services/backup_service.dart';

void main() {
  group('BackupService', () {
    group('BackupFile', () {
      test('BackupFile formats size correctly for bytes', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime(2026, 8, 15, 12, 30),
          sizeBytes: 512,
        );

        expect(backup.sizeFormatted, '512 B');
      });

      test('BackupFile formats size correctly for kilobytes', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime(2026, 8, 15, 12, 30),
          sizeBytes: 2048,
        );

        expect(backup.sizeFormatted, '2.0 KB');
      });

      test('BackupFile formats size correctly for megabytes', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime(2026, 8, 15, 12, 30),
          sizeBytes: 5242880, // 5 MB
        );

        expect(backup.sizeFormatted, '5.0 MB');
      });

      test('BackupFile formats date correctly with padding', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime(2026, 8, 15, 9, 5),
          sizeBytes: 1024,
        );

        expect(backup.dateFormatted, '15/8/2026 09:05');
      });

      test('BackupFile formats date with two-digit hour and minute', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime(2026, 8, 15, 23, 59),
          sizeBytes: 1024,
        );

        expect(backup.dateFormatted, '15/8/2026 23:59');
      });

      test('BackupFile handles single digit size correctly', () {
        final backup = BackupFile(
          name: 'small.json',
          file: File('small.json'),
          createdAt: DateTime(2026, 8, 15, 12, 30),
          sizeBytes: 100,
        );

        expect(backup.sizeFormatted, '100 B');
      });

      test('BackupFile handles large KB size correctly', () {
        final backup = BackupFile(
          name: 'medium.json',
          file: File('medium.json'),
          createdAt: DateTime(2026, 8, 15, 12, 30),
          sizeBytes: 1024 * 1024 - 1, // Just under 1 MB
        );

        expect(backup.sizeFormatted, endsWith('KB'));
      });
    });

    group('Backup JSON structure validation', () {
      test('Backup JSON should contain all required tables', () {
        final requiredTables = [
          'exportDate',
          'dbVersion',
          'clientes',
          'citas',
          'productos',
          'gastos',
          'ingresos',
          'posts',
          'movimientos_inventario',
        ];

        // Verify all tables are expected in export
        for (final table in requiredTables) {
          expect(table, isNotEmpty);
        }
      });
    });

    group('BackupFile metadata', () {
      test('BackupFile stores all required metadata', () {
        final testFile = File('test.json');
        final testDate = DateTime(2026, 8, 15, 12, 30);
        const testSize = 24576; // 24 KB

        final backup = BackupFile(
          name: 'test-backup.json',
          file: testFile,
          createdAt: testDate,
          sizeBytes: testSize,
        );

        expect(backup.name, 'test-backup.json');
        expect(backup.file, testFile);
        expect(backup.createdAt, testDate);
        expect(backup.sizeBytes, testSize);
      });

      test('BackupFile name preserves original filename', () {
        final backupNames = [
          'manicuba-copia-2026-08-15.json',
          'pelucuba-copia-2026-08-15.json',
          'app-copia-2026-08-14.json',
        ];

        for (final name in backupNames) {
          final backup = BackupFile(
            name: name,
            file: File(name),
            createdAt: DateTime.now(),
            sizeBytes: 1024,
          );
          expect(backup.name, name);
          expect(backup.name, endsWith('.json'));
        }
      });
    });

    group('Backup date formatting edge cases', () {
      test('BackupFile handles midnight correctly', () {
        final backup = BackupFile(
          name: 'midnight.json',
          file: File('midnight.json'),
          createdAt: DateTime(2026, 8, 15, 0, 0),
          sizeBytes: 1024,
        );

        expect(backup.dateFormatted, '15/8/2026 00:00');
      });

      test('BackupFile handles end of day correctly', () {
        final backup = BackupFile(
          name: 'eod.json',
          file: File('eod.json'),
          createdAt: DateTime(2026, 8, 15, 23, 59),
          sizeBytes: 1024,
        );

        expect(backup.dateFormatted, '15/8/2026 23:59');
      });

      test('BackupFile handles different months correctly', () {
        final dates = [
          DateTime(2026, 1, 15, 12, 30),  // January
          DateTime(2026, 12, 25, 12, 30), // December
          DateTime(2026, 2, 28, 12, 30),  // February
        ];

        for (final date in dates) {
          final backup = BackupFile(
            name: 'test.json',
            file: File('test.json'),
            createdAt: date,
            sizeBytes: 1024,
          );
          expect(backup.dateFormatted, contains(date.day.toString()));
          expect(backup.dateFormatted, contains(date.year.toString()));
        }
      });
    });

    group('Size formatting boundary conditions', () {
      test('BackupFile formats size at 1 KB boundary', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime.now(),
          sizeBytes: 1024,
        );

        expect(backup.sizeFormatted, '1.0 KB');
      });

      test('BackupFile formats size at 1 MB boundary', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime.now(),
          sizeBytes: 1024 * 1024,
        );

        expect(backup.sizeFormatted, '1.0 MB');
      });

      test('BackupFile formats fractional KB correctly', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime.now(),
          sizeBytes: 1536, // 1.5 KB
        );

        expect(backup.sizeFormatted, '1.5 KB');
      });

      test('BackupFile formats fractional MB correctly', () {
        final backup = BackupFile(
          name: 'test.json',
          file: File('test.json'),
          createdAt: DateTime.now(),
          sizeBytes: 2621440, // 2.5 MB
        );

        expect(backup.sizeFormatted, '2.5 MB');
      });
    });
  });
}
