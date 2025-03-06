import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:drawing_animation/drawing_animation.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intelligence/intelligence.dart';
import 'package:intelligence/model/representable.dart';

void main() {
  runApp(const CupertinoApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _intelligencePlugin = Intelligence();
  final _receivedItems = [];

  @override
  void initState() {
    super.initState();
    unawaited(requestPermissions());
    unawaited(init());
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();

    if (statuses[Permission.microphone]!.isDenied ||
        statuses[Permission.speech]!.isDenied) {
      debugPrint("❌ Permissions denied!");
    } else {
      debugPrint("✅ Permissions granted!");
    }
  }

  Future<void> init() async {
    try {
      await _intelligencePlugin.populate(const [
        Representable(representation: 'Heart', id: 'heart'),
        Representable(representation: 'Circle', id: 'circle'),
        Representable(representation: 'Rectangle', id: 'rectangle'),
        Representable(representation: 'Triangle', id: 'triangle'),
      ]);
      _intelligencePlugin.selectionsStream().listen(_handleSelection);
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handleSelection(String taskId) {
    debugPrint("🔄 Processing task STARTED: $taskId");

    Timer(Duration(seconds: 5), () async {
      bool isSuccess = Random().nextBool();
      String statusMessage = isSuccess
          ? "✅ Task $taskId successfully completed"
          : "❌ Task $taskId failed";

      debugPrint(statusMessage);

      setState(() {
        _receivedItems.add(taskId);
      });

      await _intelligencePlugin.backgroundResponse(statusMessage);

      debugPrint("✅ Processing task step completed: $taskId");
    });

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => DrawPage(shape: Shape.fromString(taskId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            leading: Icon(CupertinoIcons.captions_bubble_fill),
            largeTitle: Text('Intelligence demo'),
          ),
          SliverList.builder(
            itemBuilder: (_, index) =>
                CupertinoListTile(title: Text(_receivedItems[index])),
            itemCount: _receivedItems.length,
          ),
        ],
      ),
    );
  }
}

enum Shape {
  heart('assets/heart.svg'),
  circle('assets/circle.svg'),
  rectangle('assets/rectangle.svg'),
  triangle('assets/triangle.svg');

  const Shape(this.asset);
  final String asset;

  static Shape fromString(String value) => switch (value) {
        'circle' => Shape.circle,
        'rectangle' => Shape.rectangle,
        'triangle' => Shape.triangle,
        _ => Shape.heart,
      };
}

class DrawPage extends StatelessWidget {
  const DrawPage({super.key, required this.shape});

  final Shape shape;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: AnimatedDrawing.svg(
            shape.asset,
            animationCurve: Curves.fastLinearToSlowEaseIn,
            run: true,
            duration: const Duration(seconds: 3),
          ),
        ),
      ),
    );
  }
}
