import 'package:dio/dio.dart' as dio;
import '../utils/polyline_decoder.dart';
import '../utils/polyline_request.dart';
import '../utils/polyline_result.dart';

@Deprecated('Use NetworkProvider instead')
class NetworkUtil {
  static const String STATUS_OK = "ok";
  final dio.Dio _dio = dio.Dio();

  ///Get the encoded string from google directions api
  ///
  Future<List<PolylineResult>> getRouteBetweenCoordinates({
    required PolylineRequest request,
    String? googleApiKey,
  }) async {
    List<PolylineResult> results = [];

    try {
      var response = await _dio
          .getUri(
            request.toUri(apiKey: googleApiKey),
            options: dio.Options(headers: request.headers),
          )
          .timeout(request.timeoutDuration);

      if (response.statusCode == 200) {
        var parsedJson = response.data;
        if (parsedJson["status"]?.toLowerCase() == STATUS_OK && parsedJson["routes"] != null && parsedJson["routes"].isNotEmpty) {
          List<dynamic> routeList = parsedJson["routes"];
          for (var route in routeList) {
            results.add(PolylineResult(
              points: PolylineDecoder.run(route["overview_polyline"]["points"]),
              errorMessage: "",
              status: parsedJson["status"],
              totalDistanceValue: route['legs'].map((leg) => leg['distance']['value']).reduce((v1, v2) => v1 + v2),
              distanceTexts: <String>[...route['legs'].map((leg) => leg['distance']['text'])],
              distanceValues: <int>[...route['legs'].map((leg) => leg['distance']['value'])],
              overviewPolyline: route["overview_polyline"]["points"],
              totalDurationValue: route['legs'].map((leg) => leg['duration']['value']).reduce((v1, v2) => v1 + v2),
              durationTexts: <String>[...route['legs'].map((leg) => leg['duration']['text'])],
              durationValues: <int>[...route['legs'].map((leg) => leg['duration']['value'])],
              endAddress: route["legs"].last['end_address'],
              startAddress: route["legs"].first['start_address'],
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return results;
  }
}
