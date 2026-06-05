import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'name': 'FitPrep Backend',
      'status': 'ok',
      'phase': 'phase_1_auth',
    },
  );
}
