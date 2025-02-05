import 'dart:async';
import 'dart:io';
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
  final int maxDuration = 10; // 6 นาที (360 วินาที)
  double startTime = 0;

  void startRecording() {
    setState(() {
      isRecording = true;
      startTime = DateTime.now().millisecondsSinceEpoch / 1000;
      elapsedSeconds = 0;
      sensorData = [];
    });

    accelerometerEvents.listen((event) async {
      if (!isRecording) return;

      double currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
      double relativeTime = currentTime - startTime;

      setState(() {
        xAxisPoints.add(FlSpot(relativeTime, event.x));
        yAxisPoints.add(FlSpot(relativeTime, event.y));
        zAxisPoints.add(FlSpot(relativeTime, event.z));
      });

      sensorData.add({
        'time': relativeTime,
        'x': event.x,
        'y': event.y,
        'z': event.z,
      });

      if (xAxisPoints.length > 100) {
        xAxisPoints.removeAt(0);
        yAxisPoints.removeAt(0);
        zAxisPoints.removeAt(0);
      }
    });

    timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(() {
        elapsedSeconds++;
        if (elapsedSeconds >= maxDuration)
          stopRecording(); // หยุดหลังจากครบ 6 นาที
      });
    });
  }

  void stopRecording() {
    setState(() => isRecording = false);
    timer?.cancel();
    saveToCsv(); // เมื่อหยุดการบันทึก จะบันทึกเป็นไฟล์ .csv
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
  }

  // บันทึกข้อมูลเป็น .csv
  Future<void> saveToCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/accelerometer_data_${DateTime.now().toIso8601String()}.csv";
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
