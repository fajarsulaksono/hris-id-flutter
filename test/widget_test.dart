import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hris_id_flutter/app.dart';
import 'package:hris_id_flutter/core/api/api_client.dart';
import 'package:hris_id_flutter/core/api/api_exception.dart';
import 'package:hris_id_flutter/core/storage/preferences.dart';
import 'package:hris_id_flutter/core/storage/token_storage.dart';
import 'package:hris_id_flutter/features/attendance/application/attendance_controller.dart';
import 'package:hris_id_flutter/features/attendance/data/attendance.dart';
import 'package:hris_id_flutter/features/attendance/data/attendance_repository.dart';
import 'package:hris_id_flutter/features/auth/application/auth_controller.dart';
import 'package:hris_id_flutter/features/auth/data/auth_repository.dart';
import 'package:hris_id_flutter/features/auth/data/user.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage([this.stored]);

  String? stored;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> write(String token) async => stored = token;

  @override
  Future<void> clear() async => stored = null;
}

class _FakeBiometricPreference extends BiometricPreference {
  const _FakeBiometricPreference();

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool value) async {}
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    this.loginResult,
    this.user,
    this.loginError,
    this.meError,
  }) : super(Dio(BaseOptions()));

  final AuthResult? loginResult;
  final User? user;
  final ApiException? loginError;
  final ApiException? meError;

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return loginResult!;
  }

  @override
  Future<User> me() async {
    final error = meError;
    if (error != null) {
      throw error;
    }
    return user!;
  }
}

class _FakeAttendanceRepository extends AttendanceRepository {
  _FakeAttendanceRepository({
    List<Attendance>? records,
    this.listError,
    this.clockInError,
    this.clockOutError,
  }) : records = records ?? [],
       super(Dio(BaseOptions()));

  List<Attendance> records;
  final ApiException? listError;
  final ApiException? clockInError;
  final ApiException? clockOutError;

  @override
  Future<List<Attendance>> listForMonth(int year, int month) async {
    final error = listError;
    if (error != null) {
      throw error;
    }

    return records
        .where(
          (record) =>
              record.attendanceDate.year == year &&
              record.attendanceDate.month == month,
        )
        .toList();
  }

  @override
  Future<Attendance> clockIn({
    required DateTime date,
    required String time,
  }) async {
    final error = clockInError;
    if (error != null) {
      throw error;
    }

    final record = Attendance(
      id: 'a-${records.length + 1}',
      employeeId: 'u-1',
      attendanceDate: date,
      checkIn: time,
    );
    records = [record, ...records];

    return record;
  }

  @override
  Future<Attendance> clockOut(
    Attendance attendance, {
    required String time,
  }) async {
    final error = clockOutError;
    if (error != null) {
      throw error;
    }

    final updated = Attendance(
      id: attendance.id,
      employeeId: attendance.employeeId,
      attendanceDate: attendance.attendanceDate,
      checkIn: attendance.checkIn,
      checkOut: time,
    );
    records = records
        .map((record) => record.id == updated.id ? updated : record)
        .toList();

    return updated;
  }
}

User buildUser({
  List<String> abilities = const [
    'view_attendance',
    'view_my_leave',
    'view_my_overtime',
    'view_payroll',
  ],
}) {
  return User(
    id: 'u-1',
    code: 'EMP001',
    fullName: 'Budi Santoso',
    email: 'budi@example.test',
    username: 'budi',
    companyName: 'PT Contoh',
    roles: const ['EMPLOYEE'],
    abilities: abilities,
  );
}

Widget _buildApp({
  _MemoryTokenStorage? storage,
  _FakeAuthRepository? repository,
  _FakeAttendanceRepository? attendanceRepository,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage ?? _MemoryTokenStorage()),
      biometricPreferenceProvider.overrideWithValue(
        const _FakeBiometricPreference(),
      ),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
      if (attendanceRepository != null)
        attendanceRepositoryProvider.overrideWithValue(attendanceRepository),
    ],
    child: const HrisApp(),
  );
}

Future<void> submitLogin(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Username'),
    username,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan layar login saat token belum ada', (tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('HRIS ID'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login sukses menyimpan token dan menampilkan beranda', (
    tester,
  ) async {
    final storage = _MemoryTokenStorage();
    const token = 'token-123';

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        repository: _FakeAuthRepository(
          loginResult: AuthResult(token: token, user: buildUser()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');

    expect(find.text('Halo, Budi Santoso 👋'), findsOneWidget);
    expect(storage.stored, token);
  });

  testWidgets('login gagal menampilkan pesan galat dan tetap di login', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginError: const ApiException(
            'Username atau password salah.',
            statusCode: 422,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'salah');

    expect(find.text('Username atau password salah.'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('restore sesi valid dari secure storage langsung ke beranda', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        storage: _MemoryTokenStorage('token-123'),
        repository: _FakeAuthRepository(user: buildUser()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Halo, Budi Santoso 👋'), findsOneWidget);
  });

  testWidgets(
    'restore sesi invalid (401) kembali ke login dan token dibersihkan',
    (tester) async {
      final storage = _MemoryTokenStorage('token-expired');

      await tester.pumpWidget(
        _buildApp(
          storage: storage,
          repository: _FakeAuthRepository(
            meError: const ApiException('Unauthenticated.', statusCode: 401),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsOneWidget);
      expect(storage.stored, isNull);
    },
  );

  testWidgets('menu navigasi ditampilkan sesuai ability pengguna', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: const AuthResult(
            token: 'token-123',
            user: User(
              id: 'u-1',
              code: 'EMP001',
              fullName: 'Budi Santoso',
              email: 'budi@example.test',
              username: 'budi',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Absensi'), findsNothing);
    expect(find.text('Cuti'), findsNothing);
    expect(find.text('Gaji'), findsNothing);
  });

  testWidgets('menu lengkap tampil saat semua ability dimiliki', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: AuthResult(token: 'token-123', user: buildUser()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');

    expect(find.text('Absensi'), findsOneWidget);
    expect(find.text('Cuti'), findsOneWidget);
    expect(find.text('Lembur'), findsWidgets);
    expect(find.text('Gaji'), findsOneWidget);
  });

  testWidgets('menu Absensi tampil dengan ability view_my_attendance saja', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: const AuthResult(
            token: 'token-123',
            user: User(
              id: 'u-1',
              code: 'EMP001',
              fullName: 'Budi Santoso',
              email: 'budi@example.test',
              username: 'budi',
              abilities: ['view_my_attendance'],
            ),
          ),
        ),
        attendanceRepository: _FakeAttendanceRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');

    expect(find.text('Absensi'), findsOneWidget);
    expect(find.text('Cuti'), findsNothing);
  });

  testWidgets('absensi: clock-in lalu clock-out memperbarui kartu hari ini', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: AuthResult(token: 'token-123', user: buildUser()),
        ),
        attendanceRepository: _FakeAttendanceRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');
    await tester.tap(find.text('Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada absensi hari ini.'), findsOneWidget);
    expect(find.text('Absen Masuk'), findsOneWidget);

    await tester.tap(find.text('Absen Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Absen Pulang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('1 hari hadir'), findsOneWidget);

    await tester.tap(find.text('Absen Pulang'));
    await tester.pumpAndSettle();

    expect(find.text('Absensi hari ini selesai.'), findsOneWidget);
    expect(find.text('Pulang'), findsOneWidget);
  });

  testWidgets('absensi: clock-in offline menampilkan snackbar tanpa crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: AuthResult(token: 'token-123', user: buildUser()),
        ),
        attendanceRepository: _FakeAttendanceRepository(
          clockInError: const ApiException('Tidak dapat terhubung ke server.'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');
    await tester.tap(find.text('Absensi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Absen Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
    expect(find.text('Absen Masuk'), findsOneWidget);
  });

  testWidgets(
    'absensi: clock-out ditolak server menampilkan snackbar dan tetap di hari itu',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          repository: _FakeAuthRepository(
            loginResult: AuthResult(token: 'token-123', user: buildUser()),
          ),
          attendanceRepository: _FakeAttendanceRepository(
            clockOutError: const ApiException('Check-out sudah dicatat.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await submitLogin(tester, 'budi', 'secret');
      await tester.tap(find.text('Absensi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Absen Masuk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Absen Pulang'));
      await tester.pumpAndSettle();

      expect(find.text('Check-out sudah dicatat.'), findsOneWidget);
      expect(find.text('Absen Pulang'), findsOneWidget);
    },
  );

  testWidgets('absensi: gagal memuat menampilkan notice dan tombol coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeAuthRepository(
          loginResult: AuthResult(token: 'token-123', user: buildUser()),
        ),
        attendanceRepository: _FakeAttendanceRepository(
          listError: const ApiException('Tidak dapat terhubung ke server.'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await submitLogin(tester, 'budi', 'secret');
    await tester.tap(find.text('Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
