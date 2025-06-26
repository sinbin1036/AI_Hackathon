// 파일: lib/naver_directions_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Directions API에서 polyline 좌표 배열 추출
Future<List<List<double>>> fetchRouteCoordinates({
  required String startLat,
  required String startLng,
  required String goalLat,
  required String goalLng,
  required String naverClientId,
  required String naverClientSecret,
}) async {
  final url =
      'https://maps.apigw.ntruss.com/map-direction/v1/driving?start=$startLng,$startLat&goal=$goalLng,$goalLat&option=traoptimal';
  final headers = {
    'X-NCP-APIGW-API-KEY-ID': naverClientId,
    'X-NCP-APIGW-API-KEY': naverClientSecret,
  };

  final response = await http.get(Uri.parse(url), headers: headers);
  if (response.statusCode != 200) throw Exception('Directions API 실패: ${response.body}');

  final json = jsonDecode(response.body);
  final polylineList = json['route']['traoptimal'][0]['path']; // [[lng,lat],[lng,lat],...]

  // [lat, lng]로 변환 (각 요소 double로 보장)
  return polylineList
      .map<List<double>>((p) => [
    (p[1] as num).toDouble(),
    (p[0] as num).toDouble()
  ])
      .toList();
}

// 입력/출력 예시:
// 입력: startLat="37.5665", startLng="126.9780", goalLat="37.5772", goalLng="126.9855"
// 출력: [[37.5665,126.978],[37.5671,126.979],...]
