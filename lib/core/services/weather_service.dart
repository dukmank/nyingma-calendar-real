import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/shared_preferences_provider.dart';

// ── Temperature unit provider ─────────────────────────────────────────────────

/// true = Celsius, false = Fahrenheit.  Defaults to Fahrenheit.
final tempUnitCelsiusProvider = StateProvider<bool>((ref) => false);

// ── Model ──────────────────────────────────────────────────────────────────────

/// Raw temperature values are always stored in Celsius internally.
/// Display strings convert based on [useCelsius].
class WeatherData {
  final double   tempC;
  final int      weatherCode;
  final String   condition;
  final IconData icon;
  final double?  highC;
  final double?  lowC;
  final String   city;

  const WeatherData({
    required this.tempC,
    required this.weatherCode,
    required this.condition,
    required this.icon,
    this.highC,
    this.lowC,
    this.city = '',
  });

  static double toF(double c) => c * 9 / 5 + 32;

  String tempDisplay(bool useCelsius) =>
      useCelsius ? '${tempC.round()}°C' : '${toF(tempC).round()}°F';

  String? highDisplay(bool useCelsius) {
    if (highC == null) return null;
    return useCelsius
        ? 'H:${highC!.round()}°'
        : 'H:${toF(highC!).round()}°';
  }

  String? lowDisplay(bool useCelsius) {
    if (lowC == null) return null;
    return useCelsius
        ? 'L:${lowC!.round()}°'
        : 'L:${toF(lowC!).round()}°';
  }
}

// ── State ──────────────────────────────────────────────────────────────────────

enum LocationStatus { unknown, denied, granted }

class WeatherState {
  final LocationStatus locationStatus;
  final WeatherData?   data;
  final bool           isLoading;

  const WeatherState({
    this.locationStatus = LocationStatus.unknown,
    this.data,
    this.isLoading = false,
  });

  WeatherState copyWith({
    LocationStatus? locationStatus,
    WeatherData?    data,
    bool?           isLoading,
  }) =>
      WeatherState(
        locationStatus: locationStatus ?? this.locationStatus,
        data:           data           ?? this.data,
        isLoading:      isLoading      ?? this.isLoading,
      );

  bool get hasLocation => locationStatus == LocationStatus.granted;
}

// ── Condition helpers ──────────────────────────────────────────────────────────

String _conditionLabel(int code) {
  if (code == 0)  return 'SUNNY';
  if (code <= 2)  return 'PARTLY CLOUDY';
  if (code <= 3)  return 'CLOUDY';
  if (code <= 48) return 'FOGGY';
  if (code <= 55) return 'DRIZZLE';
  if (code <= 67) return 'RAINY';
  if (code <= 77) return 'SNOWY';
  if (code <= 82) return 'SHOWERS';
  if (code <= 99) return 'STORMY';
  return 'UNKNOWN';
}

IconData _conditionIcon(int code) {
  if (code == 0)  return Icons.wb_sunny_outlined;
  if (code <= 2)  return Icons.wb_cloudy_outlined;
  if (code <= 3)  return Icons.cloud_outlined;
  if (code <= 48) return Icons.foggy;
  if (code <= 67) return Icons.umbrella_outlined;
  if (code <= 77) return Icons.ac_unit_outlined;
  if (code <= 82) return Icons.grain_outlined;
  return Icons.thunderstorm_outlined;
}

// ── Reverse geocoding via Nominatim (OSM) ─────────────────────────────────────
//
// Uses OpenStreetMap Nominatim — free, no API key, reliable on all devices.
// Does NOT require geocoding package or Google Play Services.

Future<String> _reverseGeocode(double lat, double lon) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
    );
    final res = await http.get(uri, headers: {
      // Nominatim requires a User-Agent header
      'User-Agent': 'NyingmapaCalendar/1.0 (nyingmapacalendar.org)',
    }).timeout(const Duration(seconds: 6));

    if (res.statusCode == 200) {
      final body    = jsonDecode(res.body) as Map<String, dynamic>;
      final address = body['address'] as Map<String, dynamic>?;
      if (address != null) {
        // Pick the most specific locality available
        final city = (address['city']
                ?? address['town']
                ?? address['village']
                ?? address['county']
                ?? '') as String;
        final country = (address['country_code'] as String? ?? '').toUpperCase();
        if (city.isNotEmpty) {
          return country.isNotEmpty ? '${city.toUpperCase()}, $country' : city.toUpperCase();
        }
      }
    }
  } catch (_) {/* fall through */}
  return '';
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier(this._ref) : super(const WeatherState()) {
    _checkPermissionSilently();
  }

  final Ref _ref;

  /// On startup: check existing permission without prompting.
  Future<void> _checkPermissionSilently() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        state = state.copyWith(
          locationStatus: LocationStatus.granted,
          isLoading: true,
        );
        await _fetchWeather();
      } else {
        state = state.copyWith(locationStatus: LocationStatus.denied);
      }
    } catch (_) {
      state = state.copyWith(locationStatus: LocationStatus.denied);
    }
  }

  /// Called when user taps "Allow" in the permission dialog.
  Future<void> requestPermission() async {
    try {
      var perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.deniedForever) {
        state = state.copyWith(locationStatus: LocationStatus.denied);
        return;
      }

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        state = state.copyWith(
          locationStatus: LocationStatus.granted,
          isLoading: true,
        );
        await _fetchWeather();
      } else {
        state = state.copyWith(locationStatus: LocationStatus.denied);
      }
    } catch (_) {
      state = state.copyWith(locationStatus: LocationStatus.denied);
    }
  }

  /// Returns true if location is permanently denied (needs Settings app).
  Future<bool> isPermanentlyDenied() async {
    try {
      return await Geolocator.checkPermission() ==
          LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // Run weather fetch + reverse geocoding in parallel for speed
      final results = await Future.wait([
        _fetchOpenMeteo(lat, lon),
        _reverseGeocode(lat, lon),
      ]);

      final weatherMap = results[0] as Map<String, dynamic>?;
      final city       = results[1] as String;

      if (weatherMap != null) {
        state = state.copyWith(
          locationStatus: LocationStatus.granted,
          isLoading: false,
          data: WeatherData(
            tempC:       weatherMap['tempC'] as double,
            weatherCode: weatherMap['code']  as int,
            condition:   _conditionLabel(weatherMap['code'] as int),
            icon:        _conditionIcon(weatherMap['code']  as int),
            highC:       weatherMap['highC'] as double?,
            lowC:        weatherMap['lowC']  as double?,
            city:        city,
          ),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>?> _fetchOpenMeteo(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weathercode'
        '&daily=temperature_2m_max,temperature_2m_min'
        '&temperature_unit=celsius'
        '&timezone=auto'
        '&forecast_days=1',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final body  = jsonDecode(res.body) as Map<String, dynamic>;
      final cur   = body['current']  as Map<String, dynamic>;
      final daily = body['daily']    as Map<String, dynamic>?;

      final highList = (daily?['temperature_2m_max'] as List?)?.cast<num>();
      final lowList  = (daily?['temperature_2m_min'] as List?)?.cast<num>();

      return {
        'tempC': (cur['temperature_2m'] as num).toDouble(),
        'code':  (cur['weathercode']    as num).toInt(),
        'highC': highList?.isNotEmpty == true ? highList!.first.toDouble() : null,
        'lowC':  lowList?.isNotEmpty  == true ? lowList!.first.toDouble()  : null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Save and apply a temperature unit preference.
  Future<void> setTempUnitCelsius(bool useCelsius) async {
    _ref.read(tempUnitCelsiusProvider.notifier).state = useCelsius;
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.spTempUnitCelsius, useCelsius);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ref);
});
