import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In-App Subscriptions test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'In-App Subscriptions test'),
    );
  }
}

// This widget is the home page of your application.
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const InApp(),
    );
  }
}

class InApp extends StatefulWidget {
  const InApp({Key? key}) : super(key: key);

  @override
  _InAppState createState() => _InAppState();
}

class _InAppState extends State<InApp> {
  StreamSubscription? _purchaseUpdatedSubscription;

  StreamSubscription? _purchaseErrorSubscription;

  final List<String> _subsList = Platform.isAndroid
      ? [
          //
        ]
      : [
          'TESTSUB001',
          //
        ];

  String _platformVersion = 'Unknown';

  List<IAPItem> _items = [];

  List<PurchasedItem> _purchases = [];

  @override
  void initState() {
    super.initState();
    initPlatformState(); // async is not allowed on initState() directly
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion =
          await FlutterInappPurchase.instance.platformVersion ?? 'Unknown';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // Init the connection
    final result = await FlutterInappPurchase.instance.initConnection;
    print('init result: $result'); // ios: $result = 'true'

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // refresh items for android
    try {
      String msg = await FlutterInappPurchase.instance.consumeAllItems;
      print('consumeAllItems: $msg'); // ios: $msg = 'no-ops in ios'
    } catch (err) {
      print('consumeAllItems error: $err');
    }

    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      print('purchase-updated: $productItem');
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('purchase-error: $purchaseError');
    });
  }

  void _requestPurchase(IAPItem item) {
    assert(item.productId != null, "productId can't be null");
    FlutterInappPurchase.instance.requestPurchase(item.productId!);
  }

  Future _getSubscriptions() async {
    print('subs to list: $_subsList');
    final items =
        await FlutterInappPurchase.instance.getSubscriptions(_subsList);
    print('subscriptions: $items');
    for (IAPItem item in items) {
      print(item.toString());
      _items.add(item);
    }
    setState(() {
      _items = items;
      _purchases = [];
    });
  }

  Future _getPurchases() async {
    final items =
        await FlutterInappPurchase.instance.getAvailablePurchases() ?? [];
    for (PurchasedItem item in items) {
      print(item.toString());
      _purchases.add(item);
    }
    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  Future _getPurchaseHistory() async {
    final items =
        await FlutterInappPurchase.instance.getPurchaseHistory() ?? [];
    for (PurchasedItem item in items) {
      print(item.toString());
      _purchases.add(item);
    }
    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  @override
  void dispose() async {
    super.dispose();
    _purchaseUpdatedSubscription?.cancel();
    _purchaseUpdatedSubscription = null;
    _purchaseErrorSubscription?.cancel();
    _purchaseErrorSubscription = null;
    await FlutterInappPurchase.instance.endConnection;
  }

  List<Widget> _renderInApps() {
    return _items.map(_renderItem).toList();
  }

  Widget _renderItem(IAPItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 5.0),
            child: Text(
              item.toString(),
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
            ),
          ),
          MaterialButton(
            color: Colors.orange,
            onPressed: () {
              print("---------- Buy Item Button Pressed");
              _requestPurchase(item);
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 48.0,
                    alignment: Alignment.centerLeft,
                    child: const Text('Buy Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _renderPurchases() {
    return _purchases.map(_renderPurchase).toList();
  }

  Widget _renderPurchase(PurchasedItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 5.0),
            child: Text(
              item.toString(),
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text('Running on: $_platformVersion\n'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Btn(
                      text: const Text('Get Subscriptions'),
                      height: 60,
                      onPressed: () {
                        print("---------- Get Subscriptions Button Pressed");
                        _getSubscriptions();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Btn(
                      text: const Text('Get Purchases'),
                      height: 60,
                      onPressed: () {
                        print("---------- Get Purchases Button Pressed");
                        _getPurchases();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Btn(
                      text: const Text('Get Purchase History'),
                      height: 60,
                      onPressed: () {
                        print("---------- Get Purchase History Button Pressed");
                        _getPurchaseHistory();
                      },
                    ),
                  ),
                ],
              ),
              Column(children: _renderInApps()),
              Column(children: _renderPurchases()),
            ],
          ),
        ],
      ),
    );
  }
}

class Btn extends StatelessWidget {
  const Btn({
    Key? key,
    required this.text,
    this.height,
    this.onPressed,
  }) : super(key: key);

  final Widget text;

  final double? height;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: height,
      color: Theme.of(context).primaryColor,
      textColor: Theme.of(context).primaryTextTheme.button?.color,
      padding: const EdgeInsets.all(0.0),
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        alignment: Alignment.center,
        child: text,
      ),
    );
  }
}
