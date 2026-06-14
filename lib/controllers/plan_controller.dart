import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/services/plan_service.dart';
import 'package:fit_prep_backend/utils/request_body.dart';
import 'package:fit_prep_backend/utils/responses.dart';

class PlanController {
  const PlanController();

  Future<Response> collection(RequestContext context) {
    return switch (context.request.method) {
      HttpMethod.get => _listPlans(context),
      HttpMethod.post => _createPlan(context),
      _ => Future.value(methodNotAllowed(['GET', 'POST'])),
    };
  }

  Future<Response> resource(RequestContext context, String planId) {
    return switch (context.request.method) {
      HttpMethod.get => _getPlan(context, planId),
      HttpMethod.patch => _updatePlan(context, planId),
      HttpMethod.delete => _deletePlan(context, planId),
      _ => Future.value(methodNotAllowed(['GET', 'PATCH', 'DELETE'])),
    };
  }

  Future<Response> _createPlan(RequestContext context) async {
    try {
      final user = context.read<User>();
      final planService = context.read<PlanService>();
      final body = await readJsonObject(context);
      final plan = await planService.createPlan(
        user: user,
        title: _stringValue(body, 'title'),
        items: _itemsValue(body),
        gymSession: _stringValue(body, 'gym_session'),
        packingTime: _stringValue(body, 'packing_time'),
        reminder: _stringValue(body, 'reminder'),
      );

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'message': 'Plan created successfully.',
          'plan': plan.toJson(),
        },
      );
    } on FormatException {
      return jsonError(
        message: 'Request body must be a JSON object.',
        statusCode: HttpStatus.badRequest,
      );
    } on PlanServiceException catch (error) {
      return _planError(error);
    }
  }

  Future<Response> _listPlans(RequestContext context) async {
    final user = context.read<User>();
    final planService = context.read<PlanService>();
    final plans = await planService.listPlans(user);

    return Response.json(
      body: {
        'plans': plans.map((plan) => plan.toJson()).toList(),
      },
    );
  }

  Future<Response> _getPlan(RequestContext context, String planId) async {
    try {
      final user = context.read<User>();
      final planService = context.read<PlanService>();
      final plan = await planService.getPlan(
        user: user,
        planId: planId,
      );

      return Response.json(body: {'plan': plan.toJson()});
    } on PlanServiceException catch (error) {
      return _planError(error);
    }
  }

  Future<Response> _updatePlan(RequestContext context, String planId) async {
    try {
      final user = context.read<User>();
      final planService = context.read<PlanService>();
      final body = await readJsonObject(context);
      final plan = await planService.updatePlan(
        user: user,
        planId: planId,
        title: _stringValue(body, 'title'),
        items: _itemsValue(body),
        gymSession: _stringValue(body, 'gym_session'),
        packingTime: _stringValue(body, 'packing_time'),
        reminder: _stringValue(body, 'reminder'),
      );

      return Response.json(
        body: {
          'message': 'Plan updated successfully.',
          'plan': plan.toJson(),
        },
      );
    } on FormatException {
      return jsonError(
        message: 'Request body must be a JSON object.',
        statusCode: HttpStatus.badRequest,
      );
    } on PlanServiceException catch (error) {
      return _planError(error);
    }
  }

  Future<Response> _deletePlan(RequestContext context, String planId) async {
    try {
      final user = context.read<User>();
      final planService = context.read<PlanService>();
      await planService.deletePlan(
        user: user,
        planId: planId,
      );

      return Response.json(
        body: {'message': 'Plan deleted successfully.'},
      );
    } on PlanServiceException catch (error) {
      return _planError(error);
    }
  }

  String _stringValue(Map<String, dynamic> body, String key) {
    return body[key]?.toString() ?? '';
  }

  List<PlanItem> _itemsValue(Map<String, dynamic> body) {
    final rawItems = body['items'];
    if (rawItems is! List) {
      return const <PlanItem>[];
    }

    final items = <PlanItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is Map<String, dynamic>) {
        items.add(PlanItem.fromJson(rawItem));
      } else if (rawItem is Map<dynamic, dynamic>) {
        items.add(PlanItem.fromJson(Map<String, dynamic>.from(rawItem)));
      }
    }

    return items;
  }

  Response _planError(PlanServiceException error) {
    return jsonError(
      message: error.message,
      statusCode: switch (error.code) {
        PlanErrorCode.validation => HttpStatus.badRequest,
        PlanErrorCode.notFound => HttpStatus.notFound,
      },
    );
  }
}
