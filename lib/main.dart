// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:convert';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

void main() {
  //Wake on lan 网卡启动
  //bios 找到wake on lan打开, 没有此项的话,如技嘉主板 开启 "平台电力管理",关闭"ErP",找到"IO PORTS",进去"Network Stack Configuration",打开PXE支持
  // 进入windows ,进入控制面板,电源选项,关闭"快速启动",右键托盘网络图标,进入适配器管理界面,右键属性,网卡高级 电源管理 取消"允许计算机关闭此设备以节约电源",
  // 否则电源管理还是会关闭网卡供电,勾选"允许此设备唤醒计算机"和"只允许幻数据包唤醒计算机"
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

typedef Callback = Function(PingSummary summary);

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<void> startPing(String host,
      {required int pingCount, Callback? callback}) async {
    final ping = Ping(host,
        encoding: const Utf8Codec(allowMalformed: true), count: pingCount);
    print("command::${ping.command}");
    ping.stream.listen((event) async {
      if (event.error != null && event.summary == null) {
        print("event :: ${event.error}");
      } else {
        if (event.response != null) {
          if (event.response is PingSummary) {
            final summary = event.response as PingSummary;
            print("event summary:: ${summary}");
            callback?.call(summary);
          } else if (event.response is PingResponse) {
            final ping = event.response as PingResponse;
            ping.ip;
            ping.ttl;
            ping.time;
          } else {
            throw Exception("不想说了");
          }
        } else if (event.summary != null) {
          final summary = event.summary as PingSummary;
          callback?.call(summary);
        }
      }
    });
  }

  Future<void> _incrementCounter() async {

    // 在命令提示符处键入“shutdown -m \ [IP 地址] -r -f”（不带引号），其中“[IP 地址]”是您要重新启动的计算机的 IP。例如，
    // 如果您要重新启动的计算机位于 192.168.0.34，请键入“shutdown -m \ 192.168.0.34 -r -f”。“-r”和“-f”标志分别告诉远程计算机重新启动和安全关闭所有打开的程序。
    // 按“Enter”确认命令并重新启动远程机器。

    //shutdown -m \ 192.168.1.113 -r -f


    String mac = 'D8:5E:D3:25:B0:5E'; //#  hongju
    String ipv4 = '192.168.1.103'; //#  LAPTOP
    // String mac = '5E:EE:75:CA:86:88'; //#  LAPTOP
    // String ipv4 = '192.168.1.220';//#  LAPTOP

    // String mac = '4c:20:b8:eb:1d:42';
    // String mac = 'd8:5e:d3:25:b0:5e';
    // String ipv4 = '192.168.1.168';

    // String ipv4 = '192.168.1.20';
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

    final Callback callback = (summary) async {
      print("event :: ${summary}");
      if (summary.errors.length == pingCount ||
          (summary.received == 0 && summary.transmitted > 0)) {
        print("嗨呀,ping不通,需要唤醒机器!!");
        //TODO 当前一个PING 都接收不到,肯定是关机或睡眠了, WOL来一下
        if (MACAddress.validate(mac) && IPv4Address.validate(ipv4)) {
          MACAddress macAddress = MACAddress(mac);
          IPv4Address ipv4Address = IPv4Address(ipv4);
          WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress, port: 7);
          await wol.wake().then((_) => print('sent'));
          Future.delayed(Duration(seconds: 20)).then((value) async {
            await startPing(ipv4, pingCount: pingCount);
          });
        }
        // chromium
      }
      else {
        if (summary.transmitted == summary.received) {
          //TODO 完整接收了和返回了,正常开机状态
          print("当前${ipv4}电脑是开机状态!准备关机");
          // shutdown -m \ 192.168.1.113 -f
          // shutdown -m \ 192.168.1.113 -r -f
          final p=await Process.start(
            'shutdown',
            ["-m ", '\\', ipv4, '-f' ],
            // environment: {'LANG': 'en_US'},
          );

          const Utf8Codec(allowMalformed: true).decodeStream(p.stdout).then((value){
            print("stdout:::${value}");
          });
        } else {
          //当前可以连通,但是有丢包,我也不知道干啥

        }
      }
    };
    await startPing(ipv4, pingCount: pingCount, callback: callback);
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
