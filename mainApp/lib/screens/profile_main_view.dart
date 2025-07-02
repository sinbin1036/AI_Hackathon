import 'package:flutter/material.dart';

class ProfileMainView extends StatelessWidget {
  final VoidCallback onNavigate;

  const ProfileMainView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('박재민 님',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('보장구 등록 번호  A11001.01',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('등록된 기기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('이동플러스 K30 Lite'),
                      Text('24V x 30Ah 배터리 총 용량 720Wh'),
                      SizedBox(height: 8),
                      Text('마지막 점검일',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('2025년 5월 3일'),
                    ],
                  ),
                ),
                const Image(
                  image: AssetImage('assets/images/wheelchair.png'),
                  width: 64,
                  height: 64,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF41867C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '내 기기 관리',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: const [
                Text('내 평균 전비',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('85Wh/km',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('제 전동휠체어는 배터리를 평균적으로 소모해요!',
                    textAlign: TextAlign.center),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          // 탭 처리
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.wheelchair_pickup), label: '저장된 기기'),
          BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: '충전소 찾기'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}
