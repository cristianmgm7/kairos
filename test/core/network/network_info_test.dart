import 'package:blueprint_app/core/network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([Connectivity])
import 'network_info_test.mocks.dart';

void main() {
  late NetworkInfoImpl networkInfo;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = NetworkInfoImpl(mockConnectivity);
  });

  group('NetworkInfo', () {
    test('returns true when connected to mobile', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.mobile],
      );

      final result = await networkInfo.isConnected;

      expect(result, true);
    });

    test('returns true when connected to wifi', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );

      final result = await networkInfo.isConnected;

      expect(result, true);
    });

    test('returns false when not connected', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );

      final result = await networkInfo.isConnected;

      expect(result, false);
    });

    test('returns false when connected to bluetooth only', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.bluetooth],
      );

      final result = await networkInfo.isConnected;

      expect(result, false);
    });
  });
}
