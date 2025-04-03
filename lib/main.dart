import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const ThaiIDApp());
}

class ThaiIDApp extends StatelessWidget {
  const ThaiIDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thai ID Reader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ThaiIDReaderScreen(),
    );
  }
}

class ThaiIDReaderScreen extends StatefulWidget {
  const ThaiIDReaderScreen({super.key});

  @override
  _ThaiIDReaderScreenState createState() => _ThaiIDReaderScreenState();
}

class _ThaiIDReaderScreenState extends State<ThaiIDReaderScreen> {
  Map<String, dynamic>? _cardData;
  String? _error;

  Future<void> readCard() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8182/read-idcard'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Raw JSON: ${jsonEncode(jsonData)}");

        if (jsonData['error'] != null) {
          setState(() {
            _cardData = null;
            _error = jsonData['error'];
          });
        } else {
          setState(() {
            _cardData = jsonData;
            _error = null;
          });
        }
      } else {
        setState(() {
          _cardData = null;
          _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อกับ API';
        });
      }
    } catch (e) {
      setState(() {
        _cardData = null;
        _error = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }

  Widget buildResult() {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }

    if (_cardData == null) {
      return const Text('ยังไม่ได้อ่านบัตร');
    }

    Uint8List? photoBytes;
    try {
      photoBytes = base64Decode(_cardData!['photo_base64'] ?? '');
    } catch (_) {}

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoBytes != null)
            Center(child: Image.memory(photoBytes, width: 160, height: 200)),
          const SizedBox(height: 16),
          buildInfoRow("เลขบัตร", _cardData!['CitizenNo']),
          buildInfoRow("ชื่อ (TH)", _cardData!['FullNameTh']),
          buildInfoRow("ชื่อ (EN)", _cardData!['FullNameEn']),
          buildInfoRow("วันเกิด", _cardData!['BirthDate']?['th']),
          buildInfoRow("เพศ", _cardData!['Gender']),
          buildInfoRow("ศาสนา", _cardData!['religion']),
          buildInfoRow("ที่อยู่", _cardData!['Address']),
          buildInfoRow("จังหวัด", _cardData!['Province']),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อ่านบัตรประชาชน')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: readCard, child: const Text('อ่านบัตร')),
            const SizedBox(height: 20),
            Expanded(child: buildResult()),
          ],
        ),
      ),
    );
  }
}
