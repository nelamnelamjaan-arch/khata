import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Monitors device connectivity for hybrid OCR/AI routing.
class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  /// Reactive online flag — true when any network interface is active.
  final RxBool isOnline = false.obs;

  /// Stream subscription handle for cleanup.
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  /// Initialize connectivity listener. Call during app bootstrap.
  Future<NetworkService> init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen(_updateStatus);

    return this;
  }

  void _updateStatus(List<ConnectivityResult> results) {
    isOnline.value = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// One-shot check — useful before calling Gemini API.
  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
    isOnline.value = online;
    return online;
  }
}
