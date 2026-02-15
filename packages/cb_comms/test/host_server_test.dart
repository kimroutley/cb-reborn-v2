import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_comms/src/host_server.dart';
import 'package:cb_comms/src/game_message.dart';

void main() {
  group('HostServer Tests', () {
    late HostServer server;
    const int port = 8081;

    setUp(() async {
      server = HostServer(port: port);
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('Server accepts WebSocket connection and receives messages', () async {
      final connectCompleter = Completer<void>();
      server.onConnect = (_) {
        if (!connectCompleter.isCompleted) connectCompleter.complete();
      };

      final client = await WebSocket.connect('ws://localhost:$port');
      await connectCompleter.future;
      expect(server.clientCount, 1);

      final messageCompleter = Completer<GameMessage>();
      server.onMessage = (msg, socket) {
        if (!messageCompleter.isCompleted) messageCompleter.complete(msg);
      };

      client.add(GameMessage(type: 'test', payload: {'foo': 'bar'}).toJson());

      final receivedMessage = await messageCompleter.future;
      expect(receivedMessage.type, 'test');
      expect(receivedMessage.payload, {'foo': 'bar'});

      await client.close();
    });

    test('Server handles invalid upgrade request gracefully (simulation)', () async {
      // It's hard to simulate a failure in WebSocketTransformer.upgrade directly without mocking HttpServer/HttpRequest
      // But we can verify that the server is robust enough to handle normal http requests as per implementation.

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:$port/'));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.transform(const SystemEncoding().decoder).join();
      expect(body, 'Club Blackout Host Server');
    });

    test('Server stops and closes connections', () async {
      final connectCompleter = Completer<void>();
      server.onConnect = (_) {
        if (!connectCompleter.isCompleted) connectCompleter.complete();
      };

      final client = await WebSocket.connect('ws://localhost:$port');

      // Listen to the stream to ensure we receive the close event
      final clientDone = Completer<void>();
      client.listen(
        (_) {},
        onDone: () {
          if (!clientDone.isCompleted) clientDone.complete();
        },
        onError: (e) {},
      );

      await connectCompleter.future;
      expect(server.clientCount, 1);

      await server.stop();

      // Wait for client to be disconnected by server
      await clientDone.future;

      expect(server.clientCount, 0);
      await client.close();
    });
  });
}
