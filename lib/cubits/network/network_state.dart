import 'package:equatable/equatable.dart';
import 'package:queue_app/core/constants.dart';

class NetworkState extends Equatable {
  const NetworkState({
    this.httpRunning = false,
    this.udpRunning = false,
    this.ipAddress,
    this.httpPort = AppConstants.httpPort,
    this.udpPort = AppConstants.udpPort,
    this.errorMessage,
  });

  final bool httpRunning;
  final bool udpRunning;
  final String? ipAddress;
  final int httpPort;
  final int udpPort;
  final String? errorMessage;

  NetworkState copyWith({
    bool? httpRunning,
    bool? udpRunning,
    String? ipAddress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NetworkState(
      httpRunning: httpRunning ?? this.httpRunning,
      udpRunning: udpRunning ?? this.udpRunning,
      ipAddress: ipAddress ?? this.ipAddress,
      httpPort: httpPort,
      udpPort: udpPort,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [httpRunning, udpRunning, ipAddress, httpPort, udpPort, errorMessage];
}
