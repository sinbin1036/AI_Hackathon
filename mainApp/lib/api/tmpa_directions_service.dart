import 'dart:convert';
import 'package:http/http.dart' as http;

/// Tmap 도보 경로 탐색 API에서 polyline 좌표 배열 추출
Future<List<List<double>>> fetchTmapWalkRoute({
  required String startLat,
  required String startLng,
  required String goalLat,
  required String goalLng,
  required String tmapApiKey,
}) async {
  final url = Uri.parse('https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1');

  final headers = {
    'Content-Type': 'application/json',
    'appKey': tmapApiKey,
  };

  final body = jsonEncode({
    'startX': startLng,
    'startY': startLat,
    'endX': goalLng,
    'endY': goalLat,
    'reqCoordType': 'WGS84GEO',
    'resCoordType': 'WGS84GEO',
    'startName': '출발지',
    'endName': '도착지',
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode != 200) {
    throw Exception('도보 경로 탐색 실패: ${response.body}');
  }

  final jsonData = jsonDecode(response.body);
  final features = jsonData['features'] as List;

  final coordinates = <List<double>>[];

  for (final feature in features) {
    final geometry = feature['geometry'];
    if (geometry['type'] == 'LineString') {
      for (final coord in geometry['coordinates']) {
        coordinates.add([(coord[1] as num).toDouble(), (coord[0] as num).toDouble()]);
      }
    }
  }

  return coordinates;
}





// 입력/출력 예시:
// 입력: startLat="37.5665", startLng="126.9780", goalLat="37.5772", goalLng="126.9855"
// 출력: [[37.5665,126.978],[37.5671,126.979],...]
