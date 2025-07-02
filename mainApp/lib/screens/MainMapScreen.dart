import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'RouteSummaryScreen.dart';
import 'DeviceInfoScreen.dart';
import 'ChargingStationScreen.dart';
import 'ProfileScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
                        : const Text('주소 검색', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RouteSummaryScreen()),
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

  // 주소 -> 좌표 변환 및 지도 이동
  Future<void> _searchAndMove(String address) async {
    setState(() {
      _error = null;
    });
    final latLng = await fetchLatLngFromAddress(address); // 선언 위치 주의
    if (latLng != null && _mapController != null) {
      // 🔥🔥 최신 방식: withParams로 한 번에 이동 + 줌! 🔥🔥
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
        _error = '주소를 찾을 수 없습니다.';
      });
    }
  }

  // 반드시 _searchAndMove 함수 "아래에" 선언!
  Future<NLatLng?> fetchLatLngFromAddress(String address) async {
    // TODO: 아래 clientId/clientSecret을 .env에서 불러오거나 안전하게 관리
    final clientId = dotenv.env['NAVER_CLIENT_ID'];
    final clientSecret = dotenv.env['NAVER_CLIENT_SECRET'];
    final encoded = Uri.encodeComponent(address);
    final url = 'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$encoded';

    print('[Geocode 요청] address: $address');
    print('[Geocode 요청] url: $url');

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId!,
        'X-NCP-APIGW-API-KEY': clientSecret!,
      },
    );
    print('[Geocode 응답] statusCode: ${res.statusCode}');
    print('[Geocode 응답] body: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      print('[Geocode 파싱] json: $jsonData');
      final addresses = jsonData['addresses'];
      if (addresses != null && addresses.isNotEmpty) {
        final addr = addresses[0];
        final lat = double.parse(addr['y']);
        final lng = double.parse(addr['x']);
        print('[Geocode 좌표] lat: $lat, lng: $lng');
        return NLatLng(lat, lng);
      } else {
        print('[Geocode] addresses 없음');
      }
    } else {
      print('[Geocode] status 200 아님');
    }
    return null;
  }
}
