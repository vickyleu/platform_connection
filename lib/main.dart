import 'dart:convert';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<void> _incrementCounter() async {
    String mac = '4c:20:b8:eb:1d:42';
    // String mac = 'd8:5e:d3:25:b0:5e';
    // String ipv4 = '192.168.1.168';
    String ipv4 = '192.168.1.20';
    // String ipv4 = '292.268.221.99';
    // String ipv4 = '192.168.1.103';
    // if(MACAddress.validate(mac) && IPv4Address.validate(ipv4)) {

    // final p=await Process.start(
    //   'ping',
    //   [...["-w", "15", "-i", "50", "-4", "-n", "3" ], "192.168.1.20"],
    //   environment: {'LANG': 'en_US'},
    // );
    // const Utf8Codec(allowMalformed: true).decodeStream(p.stdout).then((value){
    //   print("stdout:::${value}");
    // });
    // // const Utf8Codec(allowMalformed: true).decodeStream(p.stdout).then((value){
    // //   print("stdout:::${value}");
    // // });


    final pingCount = 3;
    final ping = Ping(ipv4,
        encoding: const Utf8Codec(allowMalformed: true),
        count: pingCount
    );
    print("command::${ping.command}");

    ping.stream.listen((event)  async {
      if(event.response!=null){
        if(event.response is PingSummary){
          final summary = event.response as PingSummary;
          if(summary.errors.length==pingCount){
            //TODO 当前一个PING 都接收不到,肯定是关机或睡眠了, WOL来一下
            if(MACAddress.validate(mac) && IPv4Address.validate(ipv4)) {
              MACAddress macAddress = MACAddress(mac);
              IPv4Address ipv4Address = IPv4Address(ipv4);
              WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress);
              await wol.wake().then((_) => print('sent'));
            }
            // chromium
          }else{
            if(summary.transmitted == summary.received){//TODO 完整接收了和返回了,正常开机状态

            }else{//当前可以连通,但是有丢包,我也不知道干啥

            }
          }
        }
        else if(event.response is PingResponse){
          final ping = event.response as PingResponse;
          ping.ip;
          ping.ttl;
          ping.time;
        }else{
          throw Exception("不想说了");
        }
      }
    });

    // }


    // setState(() {
    //   // This call to setState tells the Flutter framework that something has
    //   // changed in this State, which causes it to rerun the build method below
    //   // so that the display can reflect the updated values. If we changed
    //   // _counter without calling setState(), then the build method would not be
    //   // called again, and so nothing would appear to happen.
    //   _counter++;
    // });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
