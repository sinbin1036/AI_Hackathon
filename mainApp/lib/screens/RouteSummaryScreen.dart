import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/tmpa_directions_service.dart';
import '../api/elevation_service.dart';


class RouteSummaryScreen extends StatefulWidget {
  const RouteSummaryScreen({super.key});

  @override
  State<RouteSummaryScreen> createState() => _RouteSummaryScreenState();
}

// 정보 저장
class RouteResponse {
  final String routeId;
  final double totalEnergy;
  final double batteryUsage;
  final bool isPossible;
  final double totalDistanceKm;
  final double totalTravelTimeMinutes;
  final double batteryEnduranceHours;

  RouteResponse({
    required this.routeId,
    required this.totalEnergy,
    required this.batteryUsage,
    required this.isPossible,
    required this.totalDistanceKm,
    required this.totalTravelTimeMinutes,
    required this.batteryEnduranceHours,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      routeId: json['route_id'],
      totalEnergy: json['total_energy'],
      batteryUsage: json['battery_usage'],
      isPossible: json['is_possible'],
      totalDistanceKm: json['total_distance_km'],
      totalTravelTimeMinutes: json['total_travel_time_minutes'],
      batteryEnduranceHours: json['battery_endurance_hours'],
    );
  }
}

class _RouteSummaryScreenState extends State<RouteSummaryScreen> {
  RouteResponse? _routeResult;
  int selectedIndex = 0;
  final TextEditingController _endController = TextEditingController();
  Position? _currentPosition;
  NPathOverlay? _pendingPathOverlay;
  NaverMapController? _mapController;
  bool _isMapVisible = false;


  @override
  void initState() {
    super.initState();
    _initLocation(); // 앱 시작 시 현재 위치 가져옴
  }

  Future<void> _initLocation() async {
    final pos = await _getCurrentPosition();
    setState(() => _currentPosition = pos);
  }

  /// 위치 권한 확인 및 현재 위치 반환
  Future<Position> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한 거부됨');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한 영구 거부됨');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  /// 키워드 기반 목적지 좌표 검색 (위도, 경도)
  Future<List<double>?> _searchLatLng(String keyword) async {
    final clientId = dotenv.env['NAVER_SEARCH_CLIENT_ID'];
    final clientSecret = dotenv.env['NAVER_SEARCH_CLIENT_SECRET'];
    final encoded = Uri.encodeComponent(keyword);
    final url = 'https://openapi.naver.com/v1/search/local.json?query=$encoded';

    print('🌐 [Naver Search] 요청 URL: $url');

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'X-Naver-Client-Id': clientId!,
        'X-Naver-Client-Secret': clientSecret!,
      },
    );

    print('📦 [Naver Search] 응답 상태코드: ${res.statusCode}');
    print('📦 [Naver Search] 응답 바디: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      final items = jsonData['items'];
      print('📌 [Naver Search] 검색 결과 개수: ${items.length}');

      if (items != null && items.isNotEmpty) {
        final first = items[0];
        final lng = double.parse(first['mapx'].toString()) / 10000000.0;
        final lat = double.parse(first['mapy'].toString()) / 10000000.0;
        print('📍 [Naver Search] 파싱된 좌표: lat=$lat, lng=$lng');
        return [lat, lng];
      } else {
        print('⚠️ [Naver Search] 검색 결과 없음.');
      }
    } else {
      print('❌ [Naver Search] 요청 실패.');
    }

    return null;
  }



  void _debugState(String tag) {
    print("🧪 [$tag] 상태 점검:");
    print(" ├ _currentPosition: $_currentPosition");
    print(" ├ _isMapVisible: $_isMapVisible");
    print(" ├ _mapController 초기화됨: ${_mapController != null}");
    print(" └ _endController 입력값: '${_endController.text}'");
  }

  Future<void> _applyPathOverlayAndMoveCamera(NPathOverlay path) async {
    if (_mapController != null) {
      await _mapController!.clearOverlays();
      await _mapController!.addOverlay(path);

      final coords = path.coords;
      final midLatLng = coords[coords.length ~/ 2];

      await _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: midLatLng,
          zoom: 16,
        ),
      );
    } else {
      _pendingPathOverlay = path;
    }
  }

  Future<void> _startNavigation() async {
    _debugState("startNavigation 호출 전");

    final goalCoords = await _searchLatLng(_endController.text);
    if (goalCoords == null) {
      print('❌ 목적지 좌표 검색 실패');
      return;
    }

    final tmapApiKey = dotenv.env['TMAP_API_KEY']!;
    final googleApiKey = dotenv.env['GOOGLE_API_KEY']!;

    try {
      // 길찾기
      final coords = await fetchTmapWalkRoute(
        startLat: _currentPosition!.latitude.toString(),
        startLng: _currentPosition!.longitude.toString(),
        goalLat: goalCoords[0].toString(),
        goalLng: goalCoords[1].toString(),
        tmapApiKey: tmapApiKey,
      );

      print('✅ 길찾기 응답 좌표 수: ${coords.length}');
      print('🗺️ 좌표 목록: $coords');

      // 길찾은 좌표값마다 고도 불러오기
      final coordsWithEle = await fetchElevationsBatch(
        latLngList: coords,
        googleApiKey: googleApiKey,
        batchSize: 512,
        maxRequests: 500,
        minDelayMs: 250,
        safeMode: true,
      );

      // 4. points -> API로 POST
      final points = coordsWithEle.map((e) => {
        "lat": e[0],
        "lng": e[1],
        "elevation": e[2],
      }).toList();

      // 고도 값 fastAPI 전송
      final response = await http.post(
        Uri.parse("http://192.168.219.102:8000/process-route-db"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": "apple",
          "points": coordsWithEle.map((e) => {
            "lat": e[0],
            "lng": e[1],
            "elevation": e[2],
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _routeResult = RouteResponse.fromJson(data);
        });
      } else {
        print("API 오류: ${response.statusCode}\n${response.body}");
      }

      final path = NPathOverlay(
        id: 'walk_route',
        coords: coords.map((c) => NLatLng(c[0], c[1])).toList(),
        width: 5,
        color: Colors.blue,
      );

      await _applyPathOverlayAndMoveCamera(path);

      setState(() {
        _isMapVisible = true;
      });

      _debugState("startNavigation setState 이후");
    } catch (e) {
      print('🚫 길찾기 실패: $e');
    }
  }

  void _onMapReady(NaverMapController controller) async {
    _mapController = controller;

    if (_pendingPathOverlay != null) {
      await _applyPathOverlayAndMoveCamera(_pendingPathOverlay!);
      _pendingPathOverlay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _debugState("build 실행");
    return Scaffold(
      body: Stack(
        children: [
          if (_isMapVisible)
            Positioned.fill(
              child: NaverMap(
                onMapReady: (controller) {
                  _onMapReady(controller);
                  print("🗺️ NaverMap 로딩 완료 (onMapReady)");
                  _debugState("onMapReady");
                },
              ),
            ),
          _buildTopBar(),
          _buildRouteOptions(),
          _buildStartButton(),
        ],
      ),
    );
  }


  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 60, 12, 20),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 40),
            Expanded(child: _buildSearchField('내 목적지', _endController)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteOptions() {
    return Positioned(
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
    );
  }

  Widget _buildStartButton() {
    return Positioned(
      bottom: 20,
      left: 32,
      right: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: _startNavigation,
        child: const Text('안내시작', style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
    );
  }

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
        decoration: InputDecoration(hintText: label, border: InputBorder.none),
      ),
    );
  }

  Widget _buildRouteOptionCard(int index, String title, String time, String distance) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
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
                child: const Text('추천', style: TextStyle(fontSize: 12, color: Colors.teal)),
              ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$time • $distance'),
          ],
        ),
      ),
    );
  }
}
