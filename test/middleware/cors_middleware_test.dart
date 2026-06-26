import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/middleware/cors_middleware.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  test('responds to OPTIONS preflight with CORS headers', () async {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/auth/register'),
        headers: {
          'origin': 'http://localhost:3000',
          'access-control-request-method': 'POST',
        },
      ),
    );

    final handler = cors()((context) => Response(body: 'should not run'));
    final response = await handler(context);

    expect(response.statusCode, HttpStatus.noContent);
    expect(response.headers[HttpHeaders.accessControlAllowOriginHeader], '*');
    expect(
      response.headers[HttpHeaders.accessControlAllowMethodsHeader],
      contains('POST'),
    );
    expect(
      response.headers[HttpHeaders.accessControlAllowHeadersHeader],
      contains('Authorization'),
    );
  });

  test('adds CORS headers to normal responses', () async {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(
      Request.get(
        Uri.parse('http://localhost/plans'),
        headers: {'origin': 'http://localhost:3000'},
      ),
    );

    final handler = cors()((context) => Response.json(body: {'ok': true}));
    final response = await handler(context);

    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers[HttpHeaders.accessControlAllowOriginHeader], '*');
  });
}
