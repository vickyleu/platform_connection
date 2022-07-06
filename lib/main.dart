// ignore_for_file: prefer_function_declarations_over_variables

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:untitled/lan_utils.dart';
import 'package:touch_indicator/touch_indicator.dart';
void main() {
  //Wake on lan 网卡启动
  //bios 找到wake on lan打开, 没有此项的话,如技嘉主板 开启 "平台电力管理",关闭"ErP",找到"IO PORTS",进去"Network Stack Configuration",打开PXE支持
  // 进入windows ,进入控制面板,电源选项,关闭"快速启动",右键托盘网络图标,进入适配器管理界面,右键属性,网卡高级 电源管理 取消"允许计算机关闭此设备以节约电源",
  // 否则电源管理还是会关闭网卡供电,勾选"允许此设备唤醒计算机"和"只允许幻数据包唤醒计算机"
  WidgetsFlutterBinding.ensureInitialized();
  getScreenInfo();
  runApp(const MyApp());
}

Future<void> getScreenInfo() async {
  var _primaryDisplay = await screenRetriever.getPrimaryDisplay();
  var _displayList = await screenRetriever.getAllDisplays();
  print("_primaryDisplay:${_primaryDisplay.toJson()}");
  print("_displayList:${_displayList.map((e) => e.toJson())}");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<ClientConfig> list = <ClientConfig>[
    ClientConfig("192.168.1.168",
        macAddress: '28:F0:76:2C:AE:E0',
        userName: 'Administrator',
        platformEnum: PlatformEnum.Windows),
    ClientConfig("192.168.1.103",
        macAddress: 'D8:5E:D3:25:B0:5E',
        userName: 'Wanghongju',
        password: 'hogan123',
        platformEnum: PlatformEnum.Windows),
    ClientConfig("192.168.1.220",
        macAddress: '54:EE:75:CA:86:88',
        userName: 'henly',
        platformEnum: PlatformEnum.Windows),
    ClientConfig("192.168.1.20",
        macAddress: '4C:20:B8:EB:1D:42',
        userName: 'xxx',
        password: 'xxx',

        ///userName: '',password: '',
        platformEnum: PlatformEnum.MacOSX),
  ];

  Future<void> _incrementCounter() async {
    //TODO (reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\ /v limitblankpassworduse /d 0 /f)
    //windows 端需要执行空密码登录添加到注册表中,否则无密码账户不能使用远程关机
    //net rpc shutdown --ipaddress 192.168.1.103 --user wanghongju%hongan123
    //shutdown -m \ 192.168.1.113 -r -f
    final config = list[1];

    final controller = WakeOnLanController(config);
    controller.checkOnline((config, status) async {
      switch (status) {
        case ClientStatus.Online:
          await controller.shutdown();
          break;
        case ClientStatus.Offline:
          await controller.wakeOnLan();
          break;
        case ClientStatus.Loss:
          // TODO: Handle this case.
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: TouchIndicator(
        child:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '0',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
