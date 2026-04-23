import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ignore: use_key_in_widget_constructors
class ApprovalPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List devices = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final res = await http.get(
      Uri.parse("http://10.241.123.58:3000/api/device/pending"),
    );

    setState(() {
      devices = jsonDecode(res.body);
    });
  }

  void approve(String id) async {
    await http.post(
      Uri.parse("http://10.241.123.58:3000/api/device/approve"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"deviceId": id}),
    );

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Approve Devices")),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(devices[i]["name"]),
            trailing: ElevatedButton(
              child: Text("Approve"),
              onPressed: () => approve(devices[i]["deviceId"]),
            ),
          );
        },
      ),
    );
  }
}