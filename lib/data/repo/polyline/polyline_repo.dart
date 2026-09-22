import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/src/network/network_client.dart';

import '../../../presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';

class PolylineRepo implements PolylineNetworkClient {
  ApiClient apiClient;
  PolylineRepo({required this.apiClient});

  @override
  Future<PolylineResult> getRouteBetweenCoordinates(PolylineRequest request) async {
    try {
      final origin = '${request.origin.latitude},${request.origin.longitude}';
      final destination = '${request.destination.latitude},${request.destination.longitude}';
      final url = "${UrlContainer.getDirection}?origin=$origin&destination=$destination";

      final response = await apiClient.request(
        url,
        Method.getMethod,
        null,
        passHeader: true,
      );

      if (response.statusCode == 200) {
        // Assuming the server returns data in a format compatible with PolylineResult.fromJson
        // or we might need to adapt it if the server returns standard Google Maps JSON
        return PolylineResult.fromJson(response.responseJson);
      } else {
        String errorMessage = response.message;
        if (response.responseJson != null && response.responseJson is Map) {
          errorMessage = response.responseJson['error_message'] ?? response.message;
        }
        return PolylineResult.error(errorMessage);
      }
    } catch (e) {
      return PolylineResult.error(e.toString());
    }
  }

  @override
  Future<RoutesApiResponse> getRouteBetweenCoordinatesV2(RoutesApiRequest request) async {
    try {
      final url = UrlContainer.getDirectionRoutesV2;
      Map<String, String> data = {
        "pickup_latitude": "${request.origin.latitude}",
        "pickup_longitude": "${request.origin.longitude}",
        "destination_latitude": "${request.destination.latitude}",
        "destination_longitude": "${request.destination.longitude}",
      };
      final response = await apiClient.request(
        url,
        Method.postMethod,
        data,
        passHeader: true,
      );

      if (response.statusCode == 200) {
        return RoutesApiResponse.fromJson(response.responseJson);
      } else {
        String errorMessage = response.message;
        if (response.responseJson != null && response.responseJson is Map) {
          errorMessage = response.responseJson['error_message'] ?? response.message;
        }
        return RoutesApiResponse.error(errorMessage);
      }
    } catch (e) {
      return RoutesApiResponse.error(e.toString());
    }
  }
}
