import 'package:flutter/material.dart';
import 'MainMapScreen.dart';
import 'NavigationScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class RouteSummaryScreen extends StatefulWidget {
  const RouteSummaryScreen({super.key});


  @override
  State<RouteSummaryScreen> createState() => _RouteSummaryScreenState();
}

class _RouteSummaryScreenState extends State<RouteSummaryScreen> {
  int selectedIndex = 0;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    final clientId = dotenv.env['NAVER_SEARCH_CLIENT_ID'];
    final clientSecret = dotenv.env['NAVER_SEARCH_CLIENT_SECRET'];
    final encoded = Uri.encodeComponent(keyword);
    final url = 'https://openapi.naver.com/v1/search/local.json?query=$encoded';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'X-Naver-Client-Id': clientId!,
        'X-Naver-Client-Secret': clientSecret!,
      },
    );

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      final items = jsonData['items'];
      if (items != null && items.isNotEmpty) {
        final first = items[0];
        final lng = double.parse(first['mapx'].toString()) / 10000000.0;
        final lat = double.parse(first['mapy'].toString()) / 10000000.0;
        print('[검색 좌표] $keyword -> lat: $lat, lng: $lng');
      } else {
        print('[검색 실패] 결과 없음: $keyword');
      }
    } else {
      print('[검색 실패] 상태 코드 ${res.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_sample.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 60, 12, 20),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/change.png',
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchField('내 위치', _startController),
                        const SizedBox(height: 8),
                        _buildSearchField('내 목적지', _endController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainMapScreen()),
                              (route) => false,
                        );
                      },
                      child: Image.asset(
                        'assets/images/back.png',
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 경로 선택 카드 리스트
          // TODO: 추천 받은 경로 기반으로 수정해야 함
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRouteOptionCard(0, '큰길우선', '20분', '921m'),
                const SizedBox(width: 12),
                _buildRouteOptionCard(1, '가장빠른길', '20분', '921m'),
                const SizedBox(width: 12),
                _buildRouteOptionCard(2, '경사낮음', '25분', '1002m'),
              ],
            ),
          ),

          // 안내시작 버튼
          Positioned(
            bottom: 20,
            left: 32,
            right: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NavigationScreen()),
                );
              },
              child: const Text(
                '안내시작',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 출발지/도착지 박스 UI
  Widget _buildSearchField(String label, TextEditingController controller) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 경로 카드 UI
  Widget _buildRouteOptionCard(int index, String title, String time, String distance) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '추천',
                  style: TextStyle(fontSize: 12, color: Colors.teal),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('$time • $distance'),
          ],
        ),
      ),
    );
  }
}
