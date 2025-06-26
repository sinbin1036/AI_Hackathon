// 파일: lib/csv_utils.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// [위도,경도,고도] 리스트를 CSV로 저장
Future<String> saveToCsvSimple(List<List<double>> data, {String filename = "result.csv"}) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$filename';

  // 각 줄: 위도,경도,고도
  final lines = data.map((e) =>
  '${e[0]},${e[1]},${e[2].round()}'
  ).join('\n');

  final file = File(path);
  await file.writeAsString(lines);
  return path;
}

// 입력/출력 예시:
/// 입력: [[37.5665,126.978,12.1],[37.5671,126.979,13.5]]
/// 출력: /data/user/0/com.example.app/files/result.csv
// 샘플 한 줄: 37.5665,126.978,12.1
