import 'package:cb_logic/cb_logic.dart';
import 'package:cb_host/main.dart';
import 'package:cb_host/host_bridge.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class FakeBox extends Fake implements Box<String> {
  @override
  bool get isOpen => true;

  @override
  Iterable<dynamic> get keys => [];

  @override
  Iterable<String> get values => [];

  @override
  String? get(key, {String? defaultValue}) => null;

  @override
  bool containsKey(key) => false;
}

class MockHostBridge extends Fake implements HostBridge {
  @override
  Future<void> start() async {} // No-op

  @override
  Future<void> stop() async {} // No-op

  @override
  bool get isRunning => true;

  @override
  Future<List<String>> getLocalIps() async => ['127.0.0.1'];

  @override
  void broadcastCurrentState() {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    PersistenceService.initWithBoxes(FakeBox(), FakeBox(), FakeBox());
  });

  testWidgets('Host app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostBridgeProvider.overrideWith((ref) => MockHostBridge()),
        ],
        child: const HostApp(),
      ),
    );
  });
}
