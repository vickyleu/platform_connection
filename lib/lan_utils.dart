import 'dart:convert';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:grpc/grpc_web.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

enum PlatformEnum {
  Windows,
  MacOSX,
  Linux,
  Android,
  iOS,
  Web,
}

enum ClientStatus {
  Online,
  Offline,
  Loss,
}

typedef Callback = Function(PingSummary summary);
typedef QueryCallback = Future<void> Function(
    ClientConfig config, ClientStatus status);

class ClientConfig {
  final String macAddress;
  final String ipv4Host;
  final String userName;
  final String password;
  final PlatformEnum platformEnum;
  final int pingCount;

  ClientConfig(this.ipv4Host,
      {required this.macAddress,
      required this.userName,
      this.password = "",
      required this.platformEnum,
      this.pingCount = 3});
}

class WakeOnLanController {
  final ClientConfig config;

  WakeOnLanController(this.config);

  Future<void> checkOnline(QueryCallback response) async {
    // ignore: prefer_function_declarations_over_variables
    final Callback callback = (summary) async {
      print("event :: $summary");
      if (summary.errors.length == config.pingCount ||
          (summary.received == 0 && summary.transmitted > 0)) {
        print("嗨呀,ping不通,需要唤醒机器!!");
        //TODO 当前一个PING 都接收不到,肯定是关机或睡眠了, WOL来一下
        await response.call(config, ClientStatus.Offline);
        // chromium
      } else {
        if (summary.transmitted == summary.received) {
          //TODO 完整接收了和返回了,正常开机状态
          print("当前${config.ipv4Host}电脑是开机状态!准备关机");
          await response.call(config, ClientStatus.Online);
        } else {
          //当前可以连通,但是有丢包,我也不知道干啥
          await response.call(config, ClientStatus.Loss);
        }
      }
    };
    await startPing(config.ipv4Host,
        pingCount: config.pingCount, callback: callback);
  }

  Future<void> shutdown() async {
    if(Platform.isLinux||Platform.isMacOS){
      final p = await Process.start(
        'net',
        ["rpc", 'shutdown','--ipaddress', config.ipv4Host,'--user','${config.userName}%${config.password}'],
      );
      const Utf8Codec(allowMalformed: true).decodeStream(p.stdout).then((value) {
        print("stdout:::${value}");
      });
    }else if(Platform.isWindows){
      final p = await Process.start(
        'shutdown',
        ["-m ", '\\', config.ipv4Host, '-f'],
      );
      const Utf8Codec(allowMalformed: true).decodeStream(p.stdout).then((value) {
        print("stdout:::${value}");
      });
    }
  }

  Future<void> wakeOnLan() async {
    if (MACAddress.validate(config.macAddress) &&
        IPv4Address.validate(config.ipv4Host)) {
      MACAddress macAddress = MACAddress(config.macAddress);
      IPv4Address ipv4Address = IPv4Address(config.ipv4Host);
      WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress, port: 7);
      await wol.wake().then((_) => print('sent'));
      Future.delayed(Duration(seconds: 20)).then((value) async {
        await startPing(config.ipv4Host, pingCount: config.pingCount);
      });
    }
  }

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
}
