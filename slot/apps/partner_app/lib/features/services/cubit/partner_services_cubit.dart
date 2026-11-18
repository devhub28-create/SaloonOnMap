import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/services_screen.dart';

abstract class PartnerServicesState {}

class PartnerServicesInitialState extends PartnerServicesState {}

class PartnerServicesLoadingState extends PartnerServicesState {}

class PartnerServicesLoadedState extends PartnerServicesState {
  final List<ServiceModel> services;
  final List<ComboModel> combos;
  final bool isOffline;

  PartnerServicesLoadedState({
    required this.services,
    required this.combos,
    this.isOffline = false,
  });
}

class PartnerServicesCubit extends Cubit<PartnerServicesState> {
  final ApiClient apiClient;

  static const String _keyServices = 'partner_services_list';
  static const String _keyCombos = 'partner_combos_list';

  PartnerServicesCubit({required this.apiClient})
      : super(PartnerServicesInitialState());

  final List<ServiceModel> _defaultServices = [];
  final List<ComboModel> _defaultCombos = [];

  ServiceModel _serviceFromJson(dynamic item) {
    return ServiceModel(
      id: item['id']?.toString() ??
          's_${DateTime.now().millisecondsSinceEpoch}',
      name: item['name']?.toString() ?? 'Salon Service',
      category: item['category']?.toString() ?? 'Hair',
      price: (item['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (item['durationMinutes'] as num?)?.toInt() ?? 30,
      isAvailable: item['isAvailable'] as bool? ?? true,
    );
  }

  ComboModel _comboFromJson(dynamic item) {
    return ComboModel(
      id: item['id']?.toString() ??
          'c_${DateTime.now().millisecondsSinceEpoch}',
      name: item['name']?.toString() ?? 'Combo Offer',
      description: item['description']?.toString() ?? '',
      price: (item['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice:
          (item['originalPrice'] ?? item['original_price'] as num?)?.toDouble(),
      discountTag: item['discountTag']?.toString() ?? '',
    );
  }

  Future<void> loadServices({String? salonId}) async {
    emit(PartnerServicesLoadingState());

    List<ServiceModel> loadedServices = [];
    List<ComboModel> loadedCombos = [];

    // Fetch live services & combos directly from backend API
    try {
      final apiServices = await apiClient.getPartnerServices(salonId: salonId);
      final apiCombos = await apiClient.getPartnerCombos(salonId: salonId);

      loadedServices = apiServices.map(_serviceFromJson).toList();
      loadedCombos = apiCombos.map(_comboFromJson).toList();

      await _saveToPrefs(loadedServices, loadedCombos);
      emit(
        PartnerServicesLoadedState(
          services: loadedServices,
          combos: loadedCombos,
        ),
      );
      return;
    } catch (_) {}

    // Fallback to local cache if offline
    try {
      final prefs = await SharedPreferences.getInstance();
      final servicesJson = prefs.getString(_keyServices);
      final combosJson = prefs.getString(_keyCombos);

      if (servicesJson != null && servicesJson.isNotEmpty) {
        final decoded = json.decode(servicesJson) as List<dynamic>;
        loadedServices = decoded
            .map(
              (item) => ServiceModel(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                category: item['category'] ?? 'Hair',
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
                durationMinutes: item['durationMinutes'] as int? ?? 30,
                isAvailable: item['isAvailable'] as bool? ?? true,
              ),
            )
            .toList();
      }

      if (combosJson != null && combosJson.isNotEmpty) {
        final decoded = json.decode(combosJson) as List<dynamic>;
        loadedCombos = decoded
            .map(
              (item) => ComboModel(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                description: item['description'] ?? '',
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
                discountTag: item['discountTag'] ?? '',
              ),
            )
            .toList();
      }
    } catch (_) {}

    emit(
      PartnerServicesLoadedState(
        services: loadedServices,
        combos: loadedCombos,
        isOffline: true,
      ),
    );
  }

  Future<bool> addService({
    required String name,
    required String category,
    required double price,
    required int durationMinutes,
    String? salonId,
  }) async {
    final currentState = state;
    final services = currentState is PartnerServicesLoadedState
        ? List<ServiceModel>.from(currentState.services)
        : List<ServiceModel>.from(_defaultServices);
    final combos = currentState is PartnerServicesLoadedState
        ? List<ComboModel>.from(currentState.combos)
        : List<ComboModel>.from(_defaultCombos);

    try {
      final saved = await apiClient.addPartnerService({
        'name': name,
        'category': category,
        'price': price,
        'durationMinutes': durationMinutes,
        if (salonId != null) 'salonId': salonId,
      });
      services.insert(0, _serviceFromJson(saved));
      emit(PartnerServicesLoadedState(services: services, combos: combos));
      await _saveToPrefs(services, combos);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCombo({
    required String name,
    required String description,
    required double price,
    required String discountTag,
    String? salonId,
  }) async {
    final currentState = state;
    final services = currentState is PartnerServicesLoadedState
        ? List<ServiceModel>.from(currentState.services)
        : List<ServiceModel>.from(_defaultServices);
    final combos = currentState is PartnerServicesLoadedState
        ? List<ComboModel>.from(currentState.combos)
        : List<ComboModel>.from(_defaultCombos);

    try {
      final saved = await apiClient.addPartnerCombo({
        'name': name,
        'description': description,
        'price': price,
        'discountTag': discountTag,
        if (salonId != null) 'salonId': salonId,
      });
      combos.insert(0, _comboFromJson(saved));
      emit(PartnerServicesLoadedState(services: services, combos: combos));
      await _saveToPrefs(services, combos);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleServiceAvailability(String serviceId) async {
    final currentState = state;
    if (currentState is PartnerServicesLoadedState) {
      final services = List<ServiceModel>.from(currentState.services);
      final index = services.indexWhere((s) => s.id == serviceId);
      if (index != -1) {
        final nextAvailability = !services[index].isAvailable;
        try {
          await apiClient.updatePartnerService(serviceId, {
            'isAvailable': nextAvailability,
          });
          services[index].isAvailable = nextAvailability;
          emit(
            PartnerServicesLoadedState(
              services: services,
              combos: currentState.combos,
            ),
          );
          await _saveToPrefs(services, currentState.combos);
          return true;
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }

  Future<void> _saveToPrefs(
    List<ServiceModel> services,
    List<ComboModel> combos,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final servicesMap = services
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'category': s.category,
              'price': s.price,
              'durationMinutes': s.durationMinutes,
              'isAvailable': s.isAvailable,
            },
          )
          .toList();

      final combosMap = combos
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'description': c.description,
              'price': c.price,
              'discountTag': c.discountTag,
            },
          )
          .toList();

      await prefs.setString(_keyServices, json.encode(servicesMap));
      await prefs.setString(_keyCombos, json.encode(combosMap));
    } catch (_) {}
  }
}
