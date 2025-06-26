// 파일: lib/elevation_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 다중좌표 고도 일괄 조회 (배치, 딜레이, 쿼터제한 안전모드 포함)
Future<List<List<double>>> fetchElevationsBatch({
  required List<List<double>> latLngList,
  required String googleApiKey,
  int batchSize = 512,
  int maxRequests = 500, // 전체 쿼터 제한
  int minDelayMs = 250,  // 1초 4회 이하(구글 권장)
  bool safeMode = true,  // 안전모드 해제 옵션
}) async {
  List<List<double>> result = [];
  int requestCount = 0;
  for (int i = 0; i < latLngList.length; i += batchSize) {
    if (safeMode && requestCount >= maxRequests) {
      throw Exception('안전모드: 최대 요청횟수($maxRequests) 초과');
    }
    final batch = latLngList.sublist(i, (i + batchSize).clamp(0, latLngList.length));
    final locations = batch.map((p) => '${p[0]},${p[1]}').join('|');
    final url =
        'https://maps.googleapis.com/maps/api/elevation/json?locations=$locations&key=$googleApiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) throw Exception('Elevation API 실패: ${resp.body}');
    final json = jsonDecode(resp.body);
    if (json['status'] != 'OK') throw Exception('Elevation API 오류: ${json['status']}');
    for (var ele in json['results']) {
      result.add([
        ele['location']['lat'].toDouble(),
        ele['location']['lng'].toDouble(),
        ele['elevation'].toDouble()
      ]);
    }
    requestCount++;
    if (safeMode && i + batchSize < latLngList.length) {
      await Future.delayed(Duration(milliseconds: minDelayMs)); // 1초 4회 이하
    }
  }
  return result;
}

// 입력/출력 예시:
/// 입력: [[37.5665,126.978],[37.5671,126.979],...]
/// 출력: [[37.5665,126.978,12.1],[37.5671,126.979,13.5],...]
