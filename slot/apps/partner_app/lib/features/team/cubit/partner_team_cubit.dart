import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/team_screen.dart';

abstract class PartnerTeamState {}

class PartnerTeamInitialState extends PartnerTeamState {}

class PartnerTeamLoadingState extends PartnerTeamState {}

class PartnerTeamLoadedState extends PartnerTeamState {
  final List<StaffMemberModel> team;

  PartnerTeamLoadedState(this.team);

  int get availableCount => team
      .where((t) => t.status == 'Available' || t.status == 'AVAILABLE')
      .length;
  int get inServiceCount => team
      .where((t) => t.status == 'In service' || t.status == 'IN_SERVICE')
      .length;
  int get breakCount =>
      team.where((t) => t.status == 'Break' || t.status == 'BREAK').length;
}

class PartnerTeamCubit extends Cubit<PartnerTeamState> {
  final ApiClient apiClient;

  static const String _keyTeam = 'partner_team_list';

  PartnerTeamCubit({required this.apiClient})
      : super(PartnerTeamInitialState());

  Future<void> loadTeam({String? salonId}) async {
    emit(PartnerTeamLoadingState());
    List<StaffMemberModel> loadedTeam = [];

    // 1. Load from local cache for quick startup/offline viewing.
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyTeam);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        loadedTeam = decoded
            .map((item) => StaffMemberModel(
                  id: item['id'] ??
                      'st_${DateTime.now().millisecondsSinceEpoch}',
                  initials: item['initials'] ?? 'ST',
                  name: item['name'] ?? 'Stylist',
                  role: item['role'] ?? 'Barber & Stylist',
                  status: item['status'] ?? 'Available',
                  jobCountToday: item['jobCountToday'] as int? ?? 0,
                ))
            .toList();
      }
    } catch (_) {}

    emit(PartnerTeamLoadedState(loadedTeam));

    // 2. Fetch from backend API and replace cache with authoritative data.
    try {
      final apiStaff = await apiClient.getPartnerStaff(salonId: salonId);
      final remoteTeam = apiStaff.map(_staffFromJson).toList();
      await _saveToPrefs(remoteTeam);
      emit(PartnerTeamLoadedState(remoteTeam));
    } catch (_) {}
  }

  StaffMemberModel _staffFromJson(dynamic item) {
    final nameStr = item['name']?.toString() ?? 'Staff member';
    final parts = nameStr.trim().split(RegExp(r'\s+'));
    final inits = item['initials']?.toString() ??
        (parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : nameStr.substring(0, nameStr.length >= 2 ? 2 : 1).toUpperCase());
    return StaffMemberModel(
      id: item['id']?.toString() ??
          'st_${DateTime.now().millisecondsSinceEpoch}',
      initials: inits,
      name: nameStr,
      role: item['roleTitle']?.toString() ??
          item['role']?.toString() ??
          'Stylist',
      status: item['status']?.toString() ?? 'AVAILABLE',
      jobCountToday: (item['jobCountToday'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> addStaff({
    required String name,
    required String role,
    required String status,
    String? salonId,
  }) async {
    final currentState = state;
    final team = currentState is PartnerTeamLoadedState
        ? List<StaffMemberModel>.from(currentState.team)
        : <StaffMemberModel>[];

    try {
      final saved = await apiClient.addPartnerStaff({
        'name': name,
        'roleTitle': role,
        'status': status,
        if (salonId != null) 'salonId': salonId,
      });
      team.insert(0, _staffFromJson(saved));
      emit(PartnerTeamLoadedState(team));
      await _saveToPrefs(team);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStaff(String staffId) async {
    final currentState = state;
    if (currentState is PartnerTeamLoadedState) {
      try {
        await apiClient.deletePartnerStaff(staffId);
        final team = List<StaffMemberModel>.from(currentState.team)
          ..removeWhere((t) => t.id == staffId);
        emit(PartnerTeamLoadedState(team));
        await _saveToPrefs(team);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> toggleStaffStatus(String staffId) async {
    final currentState = state;
    if (currentState is PartnerTeamLoadedState) {
      final team = List<StaffMemberModel>.from(currentState.team);
      final index = team.indexWhere((t) => t.id == staffId);
      if (index != -1) {
        final current = team[index].status;
        String next = 'Available';
        if (current == 'Available' || current == 'AVAILABLE') {
          next = 'In service';
        } else if (current == 'In service' || current == 'IN_SERVICE') {
          next = 'Break';
        } else {
          next = 'Available';
        }
        try {
          await apiClient.updatePartnerStaff(staffId, {'status': next});
          team[index].status = next;
          emit(PartnerTeamLoadedState(team));
          await _saveToPrefs(team);
          return true;
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }

  Future<void> _saveToPrefs(List<StaffMemberModel> team) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapList = team
          .map((t) => {
                'id': t.id,
                'initials': t.initials,
                'name': t.name,
                'role': t.role,
                'status': t.status,
                'jobCountToday': t.jobCountToday,
              })
          .toList();
      await prefs.setString(_keyTeam, json.encode(mapList));
    } catch (_) {}
  }
}
