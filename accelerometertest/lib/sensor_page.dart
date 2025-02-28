import 'dart:async';
import 'dart:io';
import 'package:accelerometertest/history_page.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerGraph extends StatefulWidget {
  @override
  _AccelerometerGraphState createState() => _AccelerometerGraphState();
}

class _AccelerometerGraphState extends State<AccelerometerGraph> {
  List<FlSpot> xAxisPoints = [];
  List<FlSpot> yAxisPoints = [];
  List<FlSpot> zAxisPoints = [];
  List<Map<String, dynamic>> sensorData = [];
  bool isRecording = false;
  Timer? timer;
  int elapsedSeconds = 0;
  final int maxDuration = 180; // 3 นาที (180 วินาที)
  double startTime = 0;
  StreamSubscription? accelerometerSubscription;

  void startRecording() {
    if (isRecording) return;

    // ยกเลิก Timer ตัวเก่าก่อนเริ่มใหม่
    timer?.cancel();

    setState(() {
      isRecording = true;
      startTime = DateTime.now().millisecondsSinceEpoch / 1000;
      elapsedSeconds = 0;
      sensorData.clear();
    });

    // ตั้งค่า Timer ให้ทำงานทุก 0.5 วินาที
    timer = Timer.periodic(Duration(milliseconds: 200), (t) async {
      final event = await accelerometerEvents.first;
      double currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
      double relativeTime = currentTime - startTime;

      setState(() {
        xAxisPoints.add(FlSpot(relativeTime, event.x));
        yAxisPoints.add(FlSpot(relativeTime, event.y));
        zAxisPoints.add(FlSpot(relativeTime, event.z));

        // ลบค่าที่เก่ากว่า 20 วินาทีออก
        while (xAxisPoints.isNotEmpty &&
            (relativeTime - xAxisPoints.first.x) > 20) {
          xAxisPoints.removeAt(0);
          yAxisPoints.removeAt(0);
          zAxisPoints.removeAt(0);
        }
      });

      sensorData.add({
        'time': relativeTime.toStringAsFixed(4),
        'x': event.x.toStringAsFixed(2),
        'y': event.y.toStringAsFixed(2),
        'z': event.z.toStringAsFixed(2),
      });

      elapsedSeconds = (relativeTime).toInt(); // คำนวณเวลาที่ผ่านไปเป็นวินาที

      if (elapsedSeconds >= maxDuration) {
        stopRecording();
        saveToCsv();
      }
    });
  }

  void stopRecording() {
    if (!isRecording) return;

    setState(() => isRecording = false);
    timer?.cancel();
    accelerometerSubscription?.cancel();
    accelerometerSubscription = null;
  }

  void resetRecording() {
    setState(() {
      isRecording = false;
      elapsedSeconds = 0;
      xAxisPoints.clear();
      yAxisPoints.clear();
      zAxisPoints.clear();
      sensorData = [];
    });
    timer?.cancel();
    accelerometerSubscription?.cancel();
    accelerometerSubscription = null;
  }

  // บันทึกข้อมูลเป็น .csv
  Future<void> saveToCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/a_data_${DateTime.now().toIso8601String()}.csv";
    final file = File(path);

    if (sensorData.isEmpty) {
      print("🚨 No data to save.");
      return;
    }

    List<String> csvData = ["Time,X,Y,Z"];
    sensorData.forEach((data) {
      csvData.add("${data['time']},${data['x']},${data['y']},${data['z']}");
    });

    await file.writeAsString(csvData.join("\n"));

    print("✅ File saved at: $path");
    resetRecording();
  }

  // ให้ไปที่หน้า history
  void navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accelerometer Graph')),
      body: Column(
        children: [
          Expanded(child: GraphWidget(xAxisPoints, yAxisPoints, zAxisPoints)),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: startRecording, child: Text("Start")),
                ElevatedButton(onPressed: stopRecording, child: Text("Stop")),
                ElevatedButton(onPressed: resetRecording, child: Text("Reset")),
              ],
            ),
          ),
          Text("Elapsed Time: $elapsedSeconds s"),
          ElevatedButton(
            onPressed: navigateToHistory,
            child: Text("View History"),
          ),
        ],
      ),
    );
  }
}

class GraphWidget extends StatelessWidget {
  final List<FlSpot> xData, yData, zData;
  GraphWidget(this.xData, this.yData, this.zData);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          minX: xData.isNotEmpty ? xData.first.x : 0,
          maxX: xData.isNotEmpty ? xData.last.x : 30,
          minY: -10,
          maxY: 10,
          lineBarsData: [
            createLine(xData, Colors.red),
            createLine(yData, Colors.green),
            createLine(zData, Colors.blue),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) =>
                      Text(value.toStringAsFixed(0))),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (value, meta) =>
                      Text(value.toStringAsFixed(1))),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  LineChartBarData createLine(List<FlSpot> data, Color color) {
    return LineChartBarData(
      spots: data,
      isCurved: true,
      color: color,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
