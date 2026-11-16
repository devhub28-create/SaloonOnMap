import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../../core/auth/admin_permissions.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../cubit/admin_users_cubit.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _role = 'ALL';
  String _status = 'ALL';
  int _page = 1;

  void _load({int? page}) {
    _page = page ?? 1;
    context.read<AdminUsersCubit>().fetchUsers(
          search: _searchController.text,
          role: _role,
          status: _status,
          page: _page,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUser(Map<String, dynamic> user, bool makeActive) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(makeActive ? 'Unblock user?' : 'Block user?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(makeActive
                ? 'This restores access for ${user['name'] ?? 'this user'}.'
                : 'This immediately revokes active sessions for ${user['name'] ?? 'this user'}.'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    makeActive ? 'Reason (optional)' : 'Reason (required)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!makeActive && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: Text(makeActive ? 'Unblock' : 'Block access'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;
    final success = await context.read<AdminUsersCubit>().setActive(
          user['id'].toString(),
          makeActive,
          reason: reason.isEmpty ? null : reason,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          success ? 'User access updated.' : 'Could not update user access.'),
    ));
  }

  Future<void> _changeRole(
      Map<String, dynamic> user, String selectedRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change administrator role?'),
        content: Text(
          '${user['name'] ?? 'This administrator'} will be signed out and receive ${selectedRole.replaceAll('_', ' ').toLowerCase()} access.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Change role')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context
        .read<AdminUsersCubit>()
        .setRole(user['id'].toString(), selectedRole);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Administrator role updated.'
          : 'Could not update administrator role.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AdminAuthCubit>().state;
    final role = authState is AdminAuthenticated ? authState.role : '';
    final currentUserId =
        authState is AdminAuthenticated ? authState.userId : '';
    final canManage = AdminPermissions.canManageUsers(role);
    final canManageRoles = AdminPermissions.canManageAdminRoles(role);

    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state is AdminUsersLoading || state is AdminUsersInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }
        if (state is AdminUsersError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AdminStatePanel.error(
              title: 'Users unavailable',
              message: state.message,
              onAction: _load,
            ),
          );
        }
        final loaded = state is AdminUsersLoaded ? state : null;
        final users = loaded?.users ?? <Map<String, dynamic>>[];

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AdminPageHeader(
              eyebrow: 'Platform users & roles',
              title: 'User management',
              description:
                  'Find customers and partners, manage account access, and assign scoped administrator roles.',
              actions: [
                IconButton.filledTonal(
                  onPressed: () => _load(page: _page),
                  tooltip: 'Refresh users',
                  icon: const Icon(Icons.refresh_rounded),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(builder: (context, constraints) {
              final search = TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: 'Search name, contact or role',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.arrow_forward_rounded)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              final role = DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                      labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    'ALL',
                    'CUSTOMER',
                    'SALON_OWNER',
                    'SALON_STAFF',
                    'ADMIN',
                    'SUPER_ADMIN',
                    'OPERATIONS_ADMIN',
                    'SUPPORT_ADMIN',
                    'MARKETING_ADMIN'
                  ]
                      .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _role = value ?? 'ALL');
                    _load();
                  });
              final status = DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                      labelText: 'Access', border: OutlineInputBorder()),
                  items: const ['ALL', 'ACTIVE', 'BLOCKED']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _status = value ?? 'ALL');
                    _load();
                  });
              return constraints.maxWidth < 760
                  ? Column(children: [
                      search,
                      const SizedBox(height: 10),
                      role,
                      const SizedBox(height: 10),
                      status
                    ])
                  : Row(children: [
                      Expanded(flex: 3, child: search),
                      const SizedBox(width: 10),
                      Expanded(child: role),
                      const SizedBox(width: 10),
                      Expanded(child: status)
                    ]);
            }),
            const SizedBox(height: AppSpacing.lg),
            if (users.isEmpty)
              const AdminStatePanel.empty(
                title: 'No users found',
                message: 'Try a different search, role, or access filter.',
              )
            else
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth >= 900
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: users.map((user) {
                    final active = user['is_active'] == true;
                    final userRole = user['role']?.toString() ?? '';
                    final isSelf = user['id']?.toString() == currentUserId;
                    final protectedSuperAdmin =
                        userRole == 'SUPER_ADMIN' && role != 'SUPER_ADMIN';
                    final scopedAdministrator = {
                      'ADMIN',
                      'OPERATIONS_ADMIN',
                      'SUPPORT_ADMIN',
                      'MARKETING_ADMIN',
                    }.contains(userRole);
                    return SizedBox(
                      width: width,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.lg),
                          leading: CircleAvatar(
                            backgroundColor: active
                                ? AppColors.statusAvailableBg
                                : const Color(0xFFFDE8E8),
                            child: Icon(
                              userRole.contains('ADMIN')
                                  ? Icons.admin_panel_settings_outlined
                                  : Icons.person_outline_rounded,
                              color: active
                                  ? AppColors.statusAvailableText
                                  : AppColors.statusDestructiveText,
                            ),
                          ),
                          title: Text(user['name']?.toString() ?? 'User',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text([
                              user['email']?.toString().isNotEmpty == true
                                  ? user['email']
                                  : user['phone'],
                              userRole.replaceAll('_', ' '),
                              active ? 'Active' : 'Blocked',
                            ].where((value) => value != null).join(' · ')),
                          ),
                          trailing: isSelf
                              ? const Tooltip(
                                  message: 'Current administrator',
                                  child: Icon(Icons.verified_user_outlined,
                                      color: AppColors.primaryGoldDark),
                                )
                              : Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (canManageRoles && scopedAdministrator)
                                      PopupMenuButton<String>(
                                        tooltip: 'Change administrator role',
                                        onSelected: (value) =>
                                            _changeRole(user, value),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'ADMIN',
                                              child: Text('Administrator')),
                                          PopupMenuItem(
                                              value: 'OPERATIONS_ADMIN',
                                              child: Text('Operations admin')),
                                          PopupMenuItem(
                                              value: 'SUPPORT_ADMIN',
                                              child: Text('Support admin')),
                                          PopupMenuItem(
                                              value: 'MARKETING_ADMIN',
                                              child: Text('Marketing admin')),
                                        ],
                                        icon: const Icon(
                                            Icons.manage_accounts_outlined),
                                      ),
                                    if (canManage && !protectedSuperAdmin)
                                      OutlinedButton(
                                        onPressed: () =>
                                            _toggleUser(user, !active),
                                        child:
                                            Text(active ? 'Block' : 'Unblock'),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            if (loaded != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                    onPressed: loaded.page > 1
                        ? () => _load(page: loaded.page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded)),
                Text('${loaded.total} users · Page ${loaded.page}'),
                IconButton(
                    onPressed: loaded.page * loaded.limit < loaded.total
                        ? () => _load(page: loaded.page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded)),
              ]),
            ],
          ],
        );
      },
    );
  }
}
