import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../widgets/info_item.dart';

class NavigationScreen extends StatefulWidget {
  final List<List<double>> routePath;

  const NavigationScreen({super.key, required this.routePath});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  NaverMapController? _mapController;
  late final List<NLatLng> _naverCoords;

  @override
  void initState() {
    super.initState();
    _naverCoords = widget.routePath.map((c) => NLatLng(c[0], c[1])).toList();
  }

  void _onMapReady(NaverMapController controller) async {
    _mapController = controller;

    final path = NPathOverlay(
      id: 'walk_route',
      coords: _naverCoords,
      width: 5,
      color: Colors.blue,
    );

    controller.addOverlay(path);

    await controller.setLocationTrackingMode(NLocationTrackingMode.follow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              child: NaverMap(
                onMapReady: _onMapReady,
                options: NaverMapViewOptions(
                  initialCameraPosition: _naverCoords.isNotEmpty
                      ? NCameraPosition(target: _naverCoords.first, zoom: 18)
                      : const NCameraPosition(target: NLatLng(35.15083, 129.01111), zoom: 18),
                  locationButtonEnable: false,
                ),
              ),
            ),
          ),
          _buildTopBar(context),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
        color: const Color(0xFF41867C),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/images/left_arrow.png', height: 36),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('34 m', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF41867C))),
                        ),
                        const SizedBox(width: 6),
                        const Text('왼쪽 방향', style: TextStyle(fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InfoItem(title: '주행전비', value: '60', unit: 'Wh'),
                        InfoItem(title: '현재 시속', value: '4', unit: 'KM'),
                        InfoItem(title: '배터리 잔량', value: '50', unit: '%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
