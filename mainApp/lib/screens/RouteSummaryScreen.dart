import 'package:flutter/material.dart';
import 'MainMapScreen.dart';
import 'NavigationScreen.dart';


class RouteSummaryScreen extends StatefulWidget {
  const RouteSummaryScreen({super.key});


  @override
  State<RouteSummaryScreen> createState() => _RouteSummaryScreenState();
}

class _RouteSummaryScreenState extends State<RouteSummaryScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 지도 이미지 배경 (PNG)
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_sample.png',
              fit: BoxFit.cover,
            ),
          ),

          // 상단 전체 흰 배경 박스
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
                  // 왼쪽: 순서 전환 버튼
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: 출발지/도착지 순서 전환 기능 구현
                      },
                      child: Image.asset(
                        'assets/images/change.png',
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 주소 입력 박스들
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchField('내 위치'),
                        const SizedBox(height: 8),
                        _buildSearchField('내 목적지'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 오른쪽: 닫기 버튼
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
  Widget _buildSearchField(String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey),
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
