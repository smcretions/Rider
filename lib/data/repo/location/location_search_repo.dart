import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import '../../../core/utils/method.dart';
import '../../../environment.dart';
import '../../model/location/prediction.dart';
import '../../../core/helper/shared_preference_helper.dart';

class LocationSearchRepo {
  final ApiClient apiClient;

  LocationSearchRepo({required this.apiClient});

  /// ✅ Detect country code (with caching and Google API fallback)
  Future<String?> detectCountryCode(Position position) async {
    // 1️⃣ Check Cache first (Optimized to avoid API hits)
    String? cachedCode = apiClient.sharedPreferences.getString(SharedPreferenceHelper.googleCountryCode);
    double? cachedLat = apiClient.sharedPreferences.getDouble(SharedPreferenceHelper.lastDetectedLat);
    double? cachedLng = apiClient.sharedPreferences.getDouble(SharedPreferenceHelper.lastDetectedLng);

    if (cachedCode != null && cachedLat != null && cachedLng != null) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        cachedLat,
        cachedLng,
      );
      // If user is within 50km of last detection, reuse the country code
      if (distance < 50000) {
        return cachedCode;
      }
    }

    String? code;

    // 2️⃣ Native reverse geocode (Free & often offline/on-device)
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      code = placemarks.first.isoCountryCode?.toLowerCase();
    } catch (_) {}

    // 3️⃣ Fallback with Google Geocoding API if null or empty (Hits the API)
    if (code == null || code.trim().isEmpty || code.isEmpty) {
      try {
        final url = '${UrlContainer.getLocationByLatlng}?lat=${position.latitude}&lng=${position.longitude}';

        final response = await apiClient.request(url, Method.getMethod, null);

        if (response.statusCode == 200) {
          final data = response.responseJson;
          if (data['status'] == 'OK' && data['results'] != null) {
            for (final result in data['results']) {
              for (final comp in result['address_components']) {
                if ((comp['types'] as List).contains('country')) {
                  code = comp['short_name'].toString().toLowerCase();
                  break;
                }
              }
              if (code != null && code.isNotEmpty) break;
            }
          }
        }
      } catch (_) {}
    }

    // 4️⃣ Update Cache if a code was found (Handles country change automatically via distance check next time)
    if (code != null && code.isNotEmpty) {
      await apiClient.sharedPreferences.setString(SharedPreferenceHelper.googleCountryCode, code);
      await apiClient.sharedPreferences.setDouble(SharedPreferenceHelper.lastDetectedLat, position.latitude);
      await apiClient.sharedPreferences.setDouble(SharedPreferenceHelper.lastDetectedLng, position.longitude);
    }

    return code ?? Environment.defaultCountryCode;
  }

  /// ✅ Get address from lat/lng (Google Geocode API)
  Future<String?> getActualAddress(double lat, double lng) async {
    final url = '${UrlContainer.getLocationByLatlng}?lat=$lat&lng=$lng';

    final response = await apiClient.request(url, Method.getMethod, null);

    if (response.statusCode == 200) {
      final data = response.responseJson;
      if (data['results'] != null && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          final types = result['types'];
          if (types != null && (types.contains('street_address') || types.contains('premise') || types.contains('subpremise') || types.contains('route') || types.contains('locality'))) {
            return result['formatted_address'];
          }
        }
        return data['results'][0]['formatted_address'];
      }

      if (data['plus_code']?['compound_code'] != null) {
        return data['plus_code']['compound_code'];
      }
    }

    return null;
  }

  /// ✅ Search address by name (auto country detect + bias)
  Future<ResponseModel> searchAddressByLocationName({
    required String text,
    required Position? position,
  }) async {
    String? countryCode;

    if (position != null) {
      countryCode = await detectCountryCode(position);
    }

    String url = '${UrlContainer.searchAddressByLocationName}?input=$text';

    if (countryCode != null && countryCode.isNotEmpty) {
      url += '&country_code=$countryCode';
    } else if (position != null) {
      // fallback: bias by user’s coordinates
      url += '&lat=${position.latitude}';
      url += '&lng=${position.longitude}';
    }

    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }

  /// ✅ Get place details by placeId
  Future<ResponseModel> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    final url = '${UrlContainer.getPlaceDetails}?place_id=${prediction.placeId}';

    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }
}
