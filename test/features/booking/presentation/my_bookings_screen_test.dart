import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ballhub/core/api/api_client.dart';
import 'package:ballhub/features/booking/data/api_booking_repository.dart';
import 'package:ballhub/features/booking/domain/models/booking.dart';
import 'package:ballhub/features/booking/presentation/controllers/booking_controllers.dart';
import 'package:ballhub/features/booking/presentation/screens/booking_detail_screen.dart';
import 'package:ballhub/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:ballhub/features/booking/presentation/widgets/booking_widgets.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...response.headers,
      },
    );
  }
}

void main() {
  setUp(() {
    ApiBookingRepository.clearLocalState();
  });

  tearDown(() {
    ApiBookingRepository.clearLocalState();
  });

  group('MyBookingsScreen Instant Loading Tests', () {
    testWidgets(
      'renders existing cached bookings instantly without full-screen loading',
      (tester) async {
        final sampleBooking = Booking(
          id: 'booking_sample_01',
          fieldId: 'field_binh_quoi',
          ownerId: 'owner_01',
          bookerId: 'current_user',
          dateKey: '2026-11-02',
          startsAt: DateTime(2026, 11, 2, 7, 0),
          endsAt: DateTime(2026, 11, 2, 8, 0),
          slotIds: const ['slot_1'],
          fieldNameSnapshot: 'Sân bóng Bình Quới',
          fieldAddressSnapshot: '1143 Bình Quới, Cư xá Thanh Đa',
          priceSnapshot: 250000,
          currency: 'VND',
          bookerNameSnapshot: 'Nguyễn Văn A',
          bookerPhoneSnapshot: '0901234567',
          status: BookingStatus.cancelledByUser,
          subtotalAmount: 250000,
          discountAmount: 0,
          totalAmount: 250000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockClient = MockHttpClient((req) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [sampleBooking.toJson()],
            }),
            200,
          );
        });
        final repo = ApiBookingRepository(
          client: ApiClient(
            baseUrl: 'http://localhost:5001/api/v1',
            client: mockClient,
          ),
        );

        // Giả lập đơn đặt sân đã được tạo trước đó trong session cục bộ
        final controller = BookingListController(
          repository: repo,
          initialBookings: [sampleBooking],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MyBookingsScreen(repository: repo, controller: controller),
          ),
        );

        expect(find.byType(BookingLoadingState), findsNothing);
        expect(find.text('Sân bóng Bình Quới'), findsOneWidget);
      },
    );

    testWidgets(
      'BookingDetailScreen renders instantly when initialBooking is provided',
      (tester) async {
        final mockClient = MockHttpClient((req) async {
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        });
        final repo = ApiBookingRepository(
          client: ApiClient(
            baseUrl: 'http://localhost:5001/api/v1',
            client: mockClient,
          ),
        );

        final sampleBooking = Booking(
          id: 'booking_sample_detail',
          fieldId: 'field_my_dinh',
          ownerId: 'owner_01',
          bookerId: 'current_user',
          dateKey: '2026-11-02',
          startsAt: DateTime(2026, 11, 2, 8, 0),
          endsAt: DateTime(2026, 11, 2, 9, 0),
          slotIds: const ['slot_2'],
          fieldNameSnapshot: 'Sân bóng Cỏ Nhân Tạo Mỹ Đình',
          fieldAddressSnapshot: 'Đường Lê Đức Thọ, Mỹ Đình',
          priceSnapshot: 250000,
          currency: 'VND',
          bookerNameSnapshot: 'Nguyễn Văn B',
          bookerPhoneSnapshot: '0909888999',
          status: BookingStatus.confirmed,
          subtotalAmount: 250000,
          discountAmount: 0,
          totalAmount: 250000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BookingDetailScreen(
              bookingId: sampleBooking.id,
              repository: repo,
              initialBooking: sampleBooking,
            ),
          ),
        );

        // Màn hình chi tiết hiển thị tức thì 0ms mà không bị che bởi spinner
        expect(find.text('Sân bóng Cỏ Nhân Tạo Mỹ Đình'), findsOneWidget);
        expect(find.byType(BookingLoadingState), findsNothing);

        await tester.pumpAndSettle();
      },
    );
  });
}
