import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/utils/async_action_runner.dart';
import 'package:ballhub/utils/async_load_state.dart';
import 'package:ballhub/utils/debouncer.dart';

void main() {
  group('Debouncer Tests', () {
    test('executes action after specified delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() {
        callCount++;
      });

      expect(callCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(callCount, 1);
      debouncer.dispose();
    });

    test(
      'resets delay on consecutive runs and only executes the last one',
      () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 60));
        String lastValue = '';

        debouncer.run(() => lastValue = 'first');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        debouncer.run(() => lastValue = 'second');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        debouncer.run(() => lastValue = 'third');

        expect(lastValue, '');
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(lastValue, 'third');
        debouncer.dispose();
      },
    );

    test('cancel stops scheduled action', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() {
        callCount++;
      });
      debouncer.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(callCount, 0);
      debouncer.dispose();
    });

    test('runAsync resolves scheduled async action after delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 40));
      String result = '';

      debouncer.runAsync(() async {
        result = 'completed';
      });

      expect(result, '');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(result, 'completed');
      debouncer.dispose();
    });
  });

  group('AsyncLoadState Tests', () {
    test('initial state has correct defaults', () {
      final state = AsyncLoadState<String>.initial();
      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.hasData, isFalse);
      expect(state.hasError, isFalse);
      expect(state.data, isNull);
    });

    test(
      'loading state has correct flags and preserves optional previous data',
      () {
        final state = AsyncLoadState<String>.loading(previousData: 'old data');
        expect(state.isLoading, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.data, 'old data');
        expect(state.hasData, isTrue);
        expect(state.hasError, isFalse);
      },
    );

    test('success state holds data', () {
      final state = AsyncLoadState<int>.success(42);
      expect(state.isLoading, isFalse);
      expect(state.hasData, isTrue);
      expect(state.data, 42);
      expect(state.hasError, isFalse);
    });

    test('error state holds error message', () {
      final state = AsyncLoadState<int>.error('Lỗi kết nối máy chủ');
      expect(state.hasError, isTrue);
      expect(state.errorMessage, 'Lỗi kết nối máy chủ');
      expect(state.isLoading, isFalse);
      expect(state.data, isNull);
    });

    test('when pattern matching executes corresponding callback', () {
      final success = AsyncLoadState<String>.success('test');
      final matched = success.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (d) => 'got: $d',
        error: (e) => 'error: $e',
      );
      expect(matched, 'got: test');

      final err = AsyncLoadState<String>.error('network fail');
      final errMatched = err.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (d) => 'got: $d',
        error: (e) => 'err: $e',
      );
      expect(errMatched, 'err: network fail');
    });
  });

  group('AsyncActionRunner Widget Tests', () {
    testWidgets('executes action and displays loading dialog', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AsyncActionRunner.run<String>(
                      context,
                      loadingTitle: 'Đang tải',
                      action: () => completer.future,
                    );
                  },
                  child: const Text('Start'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      // Hộp thoại tải dữ liệu phải được hiển thị
      expect(find.text('Đang tải'), findsOneWidget);

      completer.complete('done');
      await tester.pumpAndSettle();

      // Hộp thoại phải được đóng lại
      expect(find.text('Đang tải'), findsNothing);
    });

    testWidgets('catches ApiException and shows friendly SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AsyncActionRunner.run<void>(
                      context,
                      action: () async {
                        throw ApiException(
                          code: 'NOT_FOUND',
                          message: 'Không tìm thấy sân bóng',
                          statusCode: 404,
                        );
                      },
                    );
                  },
                  child: const Text('Trigger Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy sân bóng'), findsOneWidget);
    });
  });

  group('AsyncElevatedButton Tests', () {
    testWidgets(
      'shows loading spinner and disables button during async action',
      (tester) async {
        final completer = Completer<void>();
        int executionCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AsyncElevatedButton(
                onPressed: () async {
                  executionCount++;
                  await completer.future;
                },
                child: const Text('Submit Form'),
              ),
            ),
          ),
        );

        expect(find.text('Submit Form'), findsOneWidget);

        // Nhấn nút để bắt đầu hành động bất đồng bộ
        await tester.tap(find.byType(AsyncElevatedButton));
        await tester.pump();

        // Trong lúc đang bận xử lý, vòng xoay loading hiển thị và nội dung ban đầu bị ẩn đi
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Submit Form'), findsNothing);

        // Thử nhấn nút lần 2 khi yêu cầu trước chưa hoàn tất
        await tester.tap(find.byType(AsyncElevatedButton));
        await tester.pump();

        // Đảm bảo hành động gửi trùng lặp đã bị chặn lại thành công
        expect(executionCount, 1);

        // Hoàn thành hành động bất đồng bộ
        completer.complete();
        await tester.pumpAndSettle();

        // Nút quay trở về trạng thái ban đầu
        expect(find.text('Submit Form'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
