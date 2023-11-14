import 'package:flutter/material.dart';

class BasicDataVisualization extends StatelessWidget {
  final String data;

  const BasicDataVisualization({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Retrieved'),
      ),
      body: Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical, child: Text(data))),
    );
  }
}
