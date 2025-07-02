import 'package:flutter/material.dart';
import 'RouteSummaryScreen.dart';

class ChargingStationScreen extends StatefulWidget {
  const ChargingStationScreen({super.key});

  @override
  State<ChargingStationScreen> createState() => _ChargingStationScreenState();
}

class _ChargingStationScreenState extends State<ChargingStationScreen> {
  int? _selectedStationIndex;

  final List<Map<String, dynamic>> _stations = [
    {
      'name': '현대오일뱅크\n전동휠체어 충전기',
      'left': 100.0,
      'top': 250.0,
    },
    {
      'name': '지하철 2호선 주례역\n전동휠체어 급속 충전기',
      'left': 50.0,
      'top': 400.0,
    },
  ];

  void _onMarkerTapped(int index) {
    setState(() {
      _selectedStationIndex = index;
    });
  }

  void _onDirectionPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 지도 이미지 (map_sample.png)
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_sample.png',
              fit: BoxFit.cover,
            ),
          ),

          // 충전소 마커 아이콘
          for (int i = 0; i < _stations.length; i++)
            Positioned(
              left: _stations[i]['left'],
              top: _stations[i]['top'],
              child: GestureDetector(
                onTap: () => _onMarkerTapped(i),
                child: Image.asset(
                  'assets/images/charging_icon1.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ),

          // 선택된 마커 정보 패널
          if (_selectedStationIndex != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _stations[_selectedStationIndex!]['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _onDirectionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF41867C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '길안내',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
