import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'RouteSummaryScreen.dart';
import 'DeviceInfoScreen.dart';
import 'ChargingStationScreen.dart';
import 'ProfileScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:proj4dart/proj4dart.dart';
import 'dart:math';

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});
  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [];
  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const MainMapContent(),
      DeviceInfoScreen(onBack: () {
        setState(() {
          _selectedIndex = 0;
        });
      }),
      const ChargingStationScreen(),
      const ProfileScreen(),
    ]);
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFF7F4F8),
        selectedItemColor: const Color(0xFF41867C),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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

// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

class MainMapContent extends StatefulWidget {
  const MainMapContent({super.key});
  @override
  State<MainMapContent> createState() => _MainMapContentState();
}

class _MainMapContentState extends State<MainMapContent> {
  final TextEditingController _searchController = TextEditingController();
  NaverMapController? _mapController;
  bool _isSearching = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(35.15083, 129.01111), //냉정역
                zoom: 14,
              ),
              indoorEnable: true,
              locationButtonEnable: true,
            ),
            onMapReady: (controller) {
              _mapController = controller;
            },
          ),
        ),
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.centerLeft,
                    child: _isSearching
                        ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '주소 입력 후 Enter',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (query) async {
                        await _searchAndMove(query);
                      },
                    )
                        : const Text(
                        '주소 검색', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RouteSummaryScreen()),
                  );
                },
                child: Image.asset(
                  'assets/images/start_map.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.redAccent,
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

// 네이버 검색(Local) API를 통한 키워드(상호/역/POI) → 좌표 변환
  Future<NLatLng?> fetchLatLngFromKeyword(String keyword) async {
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
        print('[Local검색 좌표 변환] lat: $lat, lng: $lng');
        return NLatLng(lat, lng);
      }
    }
    return null;
  }

// 기존 _searchAndMove 함수는 그대로 사용
  Future<void> _searchAndMove(String query) async {
    setState(() {
      _error = null;
    });
    final latLng = await fetchLatLngFromKeyword(query); // 변환 적용!
    if (latLng != null && _mapController != null) {
      await _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: latLng,
          zoom: 16,
        ),
      );
      FocusScope.of(context).unfocus();
      setState(() {
        _isSearching = false;
      });
    } else {
      setState(() {
        _error = '검색 결과를 찾을 수 없습니다.';
      });
    }
  }
}