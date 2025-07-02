import 'package:flutter/material.dart';

class InputSearchScreen extends StatelessWidget {
  const InputSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목적지 검색 화면'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('목적지 검색 화면'),
            const SizedBox(height: 20),
            // TODO: 목적지 입력 및 검색 기능 구현 예정
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/route'),
              child: const Text('경로 요약 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
