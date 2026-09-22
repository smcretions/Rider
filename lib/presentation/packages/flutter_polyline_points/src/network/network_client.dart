import '../utils/polyline_request.dart';
import '../utils/polyline_result.dart';
import '../routes_api/routes_request.dart';
import '../routes_api/routes_response.dart';

/// Interface for network operations in PolylinePoints
/// Allows providing custom network implementations (e.g., via proxy server)
abstract class PolylineNetworkClient {
  /// Get route using legacy Directions API format
  Future<PolylineResult> getRouteBetweenCoordinates(PolylineRequest request);

  /// Get route using new Routes API format
  Future<RoutesApiResponse> getRouteBetweenCoordinatesV2(RoutesApiRequest request);
}
