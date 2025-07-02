import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'screens/MainMapScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_CLIENT_ID']!, // .env에서 키 읽어옴
    // onAuthFailed: (e) => print('네이버맵 인증 실패: $e'), // 필요 시
  );

  runApp(MaterialApp(
    home: const MainMapScreen(),
    debugShowCheckedModeBanner: false,
  ));
}



















// 이 밑은 api 구현 로직
//이따가 RouteSummaryScreen.dart에 삽입예정


// import 'package:flutter/material.dart';
// import 'api/naver_directions_service.dart';
// import 'api/elevation_service.dart';
// import 'api/csv_utils.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화(반드시 첫 줄)
//   await dotenv.load();
//
//   final naverClientId = dotenv.env['NAVER_CLIENT_ID']!;
//   final naverClientSecret = dotenv.env['NAVER_CLIENT_SECRET']!;
//   final googleApiKey = dotenv.env['GOOGLE_API_KEY']!;
//   final startLat = "37.5665", startLng = "126.9780";
//   final goalLat = "37.5772", goalLng = "126.9855";
//
//   try {
//     // 1. 경로 Polyline 추출
//     final coords = await fetchRouteCoordinates(
//       startLat: startLat, startLng: startLng,
//       goalLat: goalLat, goalLng: goalLng,
//       naverClientId: naverClientId,
//       naverClientSecret: naverClientSecret,
//     );
//
//     // 2. 고도값 조회 (API 요청안전모드 ON)
//     final coordsWithEle = await fetchElevationsBatch(
//       latLngList: coords,
//       googleApiKey: googleApiKey,
//       batchSize: 512,
//       maxRequests: 500,
//       minDelayMs: 250,
//       safeMode: true,
//     );
//
//     // 3. csv로 저장
//     final path = await saveToCsvSimple(coordsWithEle, filename: "my_path.csv");
//     print('CSV 저장 위치: $path');
//
//     // 4. points -> API로 POST
//     final points = coordsWithEle.map((e) => {
//       "lat": e[0],
//       "lng": e[1],
//       "elevation": e[2],
//     }).toList();
//
//     final apiPayload = {
//       "route_id": "flutter_route",
//       "points": points,
//       "user_data": {"weight": 75},           // 테스트용 값, 필요시 변경
//       "battery_data": {"capacity": 600, "soc": 90}
//     };
//
//     final response = await http.post(
//       Uri.parse("http://10.0.2.2:8000/process-route"), // localhost 대신!
//       headers: {"Content-Type": "application/json"},
//       body: json.encode(apiPayload),
//     );
//
//     if (response.statusCode == 200) {
//       print("AI 분석 결과: ${response.body}");
//     } else {
//       print("API 오류: ${response.statusCode}\n${response.body}");
//     }
//
//   } catch (e, st) {
//     print("오류: $e\n$st");
//   }
// }
