import 'package:network_info_plus/network_info_plus.dart';

/// Тонкая обёртка над network_info_plus.
class NetworkInfoService {
  final NetworkInfo _info = NetworkInfo();

  Future<String?> getWifiIp() async {
    try {
      return await _info.getWifiIP();
    } catch (_) {
      return null;
    }
  }
}
