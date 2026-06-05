import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with backend status.', () async {
      final context = _MockRequestContext();
      final response = route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['name'], 'FitPrep Backend');
      expect(body['status'], 'ok');
      expect(body['phase'], 'phase_1_auth');
    });
  });
}
