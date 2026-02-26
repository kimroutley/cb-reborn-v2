import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import '../colors.dart';
import '../haptic_service.dart';
import '../widgets.dart';

class CBGuideScreen extends StatefulWidget {
  final GameState? gameState;
  final Player? localPlayer;
  final Widget? drawer;

  const CBGuideScreen({
    super.key,
    this.gameState,
    this.localPlayer,
    this.drawer,
  });

  @override
  State<CBGuideScreen> createState() => _CBGuideScreenState();
}

class _CBGuideScreenState extends State<CBGuideScreen>
    with SingleTickerProviderStateMixin {
  Role? _selectedRoleForTips;
  String _searchQuery = "";
  int _activeMainIndex = 0;
  int _activeHandbookCategoryIndex = 0;

  bool _isPanelOpen = false;
  Role? _selectedDossierRole;

  static const double _phoneBreakpoint = 600;

  bool _isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _phoneBreakpoint;

  @override
  void initState() {
    super.initState();
    _selectedRoleForTips = widget.localPlayer?.role ?? roleCatalog.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = _isPhone(context);

    return CBPrismScaffold(
      title: "THE BLACKBOOK",
      drawer: widget.drawer,
      body: phone ? _buildPhoneLayout(scheme, theme) : _buildTabletLayout(scheme, theme),
    );
  }

  // ── PHONE LAYOUT: bottom nav + full-width content ──

  Widget _buildPhoneLayout(ColorScheme scheme, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildActiveContent(),
          ),
        ),
        _buildBottomNav(scheme, theme),
      ],
    );
  }

  Widget _buildBottomNav(ColorScheme scheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.menu_book_rounded,
                label: 'MANUAL',
                isActive: _activeMainIndex == 0,
                activeColor: scheme.primary,
                onTap: () => setState(() {
                  _activeMainIndex = 0;
                  HapticService.selection();
                }),
              ),
              _BottomNavItem(
                icon: Icons.groups_rounded,
                label: 'OPERATIVES',
                isActive: _activeMainIndex == 1,
                activeColor: scheme.primary,
                onTap: () => setState(() {
                  _activeMainIndex = 1;
                  HapticService.selection();
                }),
              ),
              _BottomNavItem(
                icon: Icons.psychology_rounded,
                label: 'INTEL',
                isActive: _activeMainIndex == 2,
                activeColor: scheme.primary,
                onTap: () => setState(() {
                  _activeMainIndex = 2;
                  HapticService.selection();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TABLET LAYOUT: side rail + content + sliding panel ──

  Widget _buildTabletLayout(ColorScheme scheme, ThemeData theme) {
    return Stack(
      children: [
        Row(
          children: [
            _buildNavigationRail(scheme, theme),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildActiveContent(),
              ),
            ),
          ],
        ),
        CBSlidingPanel(
          isOpen: _isPanelOpen,
          onClose: () => setState(() => _isPanelOpen = false),
          title: _selectedDossierRole?.name ?? "DATA FILE",
          width: 420,
          accentColor: _selectedDossierRole != null
              ? CBColors.fromHex(_selectedDossierRole!.colorHex)
              : null,
          child: _selectedDossierRole != null
              ? SingleChildScrollView(
                  child: _buildOperativeDetails(context, _selectedDossierRole!),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(ColorScheme scheme, ThemeData theme) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _RailItem(
              icon: Icons.menu_book_rounded,
              label: "MANUAL",
              isActive: _activeMainIndex == 0,
              onTap: () => setState(() {
                _activeMainIndex = 0;
                HapticService.selection();
              }),
            ),
            _RailItem(
              icon: Icons.groups_rounded,
              label: "OPERATIVES",
              isActive: _activeMainIndex == 1,
              onTap: () => setState(() {
                _activeMainIndex = 1;
                HapticService.selection();
              }),
            ),
            _RailItem(
              icon: Icons.psychology_rounded,
              label: "INTEL",
              isActive: _activeMainIndex == 2,
              onTap: () => setState(() {
                _activeMainIndex = 2;
                HapticService.selection();
              }),
            ),
            if (_activeMainIndex == 0) ...[
              const SizedBox(height: 20),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.1),
                indent: 20,
                endIndent: 20,
              ),
              const SizedBox(height: 10),
              ...List.generate(6, (index) {
                final icons = [
                  Icons.nightlife_rounded,
                  Icons.loop_rounded,
                  Icons.groups_rounded,
                  Icons.wine_bar_rounded,
                  Icons.settings_remote_rounded,
                  Icons.smartphone_rounded,
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _RailItem(
                    icon: icons[index],
                    label: "",
                    isActive: _activeHandbookCategoryIndex == index,
                    isSubItem: true,
                    onTap: () => setState(() {
                      _activeHandbookCategoryIndex = index;
                      HapticService.light();
                    }),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    final phone = _isPhone(context);
    switch (_activeMainIndex) {
      case 0:
        return Column(
          children: [
            if (phone) _buildHandbookChips(),
            Expanded(
              child: CBIndexedHandbook(
                gameState: widget.gameState,
                activeCategoryIndex: _activeHandbookCategoryIndex,
                onCategoryChanged: (index) =>
                    setState(() => _activeHandbookCategoryIndex = index),
              ),
            ),
          ],
        );
      case 1:
        return CBFadeSlide(child: _buildOperativesTab());
      case 2:
        return CBFadeSlide(child: _buildIntelTab());
      default:
        return const SizedBox();
    }
  }

  // ── Phone handbook section chips (replaces rail sub-icons) ──

  Widget _buildHandbookChips() {
    final scheme = Theme.of(context).colorScheme;
    const labels = ['OVERVIEW', 'HOW TO PLAY', 'ALLIANCES', 'BAR TAB', 'HOST', 'COMPANION'];
    const icons = [
      Icons.nightlife_rounded,
      Icons.loop_rounded,
      Icons.groups_rounded,
      Icons.wine_bar_rounded,
      Icons.settings_remote_rounded,
      Icons.smartphone_rounded,
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.1)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final isActive = _activeHandbookCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _activeHandbookCategoryIndex = index);
              HapticService.light();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? scheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.4)
                      : scheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    size: 14,
                    color: isActive
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: 0.8,
                      color: isActive
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Operatives (Interactive Browser) ──

  Widget _buildOperativesTab() {
    final allRoles = roleCatalog.isEmpty ? <Role>[] : roleCatalog;
    final phone = _isPhone(context);

    final filteredRoles = allRoles
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.type
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    if (allRoles.isEmpty) {
      return Center(
          child: Text("NO OPERATIVE DATA FOUND",
              style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }

    final hPad = phone ? 14.0 : 20.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
          child: CBTextField(
            hintText: "SEARCH DOSSIERS...",
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
            itemCount: filteredRoles.length,
            itemBuilder: (context, index) {
              final role = filteredRoles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CBRoleIDCard(
                  role: role,
                  onTap: () {
                    HapticService.light();
                    _showOperativeFile(role);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOperativeFile(Role role) {
    if (_isPhone(context)) {
      _showOperativeDossierSheet(role);
    } else {
      setState(() {
        _selectedDossierRole = role;
        _isPanelOpen = true;
      });
    }
  }

  void _showOperativeDossierSheet(Role role) {
    final color = CBColors.fromHex(role.colorHex);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          final scheme = Theme.of(ctx).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
                left: BorderSide(color: color.withValues(alpha: 0.15)),
                right: BorderSide(color: color.withValues(alpha: 0.15)),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          role.name.toUpperCase(),
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w900,
                                color: color,
                                shadows: CBColors.textGlow(color),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildOperativeDetails(ctx, role),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOperativeDetails(BuildContext context, Role role) {
    final color = CBColors.fromHex(role.colorHex);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final phone = _isPhone(context);
    final hPad = phone ? 16.0 : 20.0;
    final avatarSize = phone ? 72.0 : 100.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Center(
              child: CBRoleAvatar(
                assetPath: role.assetPath,
                color: color,
                size: avatarSize,
                breathing: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          CBFadeSlide(
            delay: const Duration(milliseconds: 150),
            child: Text(
              role.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge!.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                fontSize: phone ? 18 : null,
                shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CBBadge(text: role.type.toUpperCase(), color: color),
                  const SizedBox(width: 8),
                  CBBadge(
                    text: _allianceShortName(role.alliance),
                    color: _allianceColor(role.alliance, scheme),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          CBFadeSlide(
            delay: const Duration(milliseconds: 250),
            child: CBGlassTile(
              borderColor: color.withValues(alpha: 0.2),
              padding: EdgeInsets.all(phone ? 12 : 16),
              child: Text(
                role.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!.copyWith(
                  height: 1.6,
                  fontSize: phone ? 13 : null,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: EdgeInsets.all(phone ? 12 : 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  if (role.ability != null && role.ability!.isNotEmpty)
                    _buildStatRow(
                      context,
                      "ABILITY",
                      role.ability!,
                      color,
                      Icons.bolt_rounded,
                    ),
                  if (role.ability != null && role.ability!.isNotEmpty)
                    const SizedBox(height: 10),
                  _buildStatRow(
                    context,
                    "WAKE PRIORITY",
                    role.nightPriority == 0 ? "PASSIVE" : "LVL ${role.nightPriority}",
                    color,
                    Icons.nightlight_round,
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    context,
                    "OBJECTIVE",
                    _winConditionFor(role),
                    color,
                    Icons.flag_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (role.tacticalTip.isNotEmpty)
            CBFadeSlide(
              delay: const Duration(milliseconds: 450),
              child: Container(
                padding: EdgeInsets.all(phone ? 12 : 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        role.tacticalTip,
                        style: textTheme.bodySmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          CBFadeSlide(
            delay: const Duration(milliseconds: 500),
            child: SizedBox(
              width: double.infinity,
              child: CBPrimaryButton(
                label: phone ? "DISMISS" : "CLOSE DOSSIER",
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                onPressed: () {
                  if (phone) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _isPanelOpen = false);
                  }
                  HapticService.light();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color color, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              value.toUpperCase(),
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _allianceShortName(Team t) => switch (t) {
        Team.clubStaff => "DEALERS",
        Team.partyAnimals => "PARTY ANIMALS",
        Team.neutral => "WILDCARD",
        _ => "UNKNOWN",
      };

  Color _allianceColor(Team t, ColorScheme scheme) => switch (t) {
        Team.clubStaff => scheme.error,
        Team.partyAnimals => scheme.primary,
        Team.neutral => scheme.tertiary,
        _ => scheme.onSurface,
      };

  String _winConditionFor(Role role) {
    return switch (role.alliance) {
      Team.clubStaff => "ELIMINATE ALL PARTY ANIMALS",
      Team.partyAnimals => "EXPOSE AND EXILE ALL DEALERS",
      Team.neutral => "FULFILL PERSONAL SURVIVAL GOALS",
      _ => "SURVIVE THE NIGHT",
    };
  }


  // ── Tab 3: Intel (Strategic Analytics & Alliance Mapping) ──
  Widget _buildIntelTab() {
    if (_selectedRoleForTips == null && roleCatalog.isNotEmpty) {
      _selectedRoleForTips = widget.localPlayer?.role ?? roleCatalog.first;
    }

    if (_selectedRoleForTips == null) {
      return const Center(child: Text("DATA UNAVAILABLE"));
    }

    final tips = _GuideStrategyGenerator.generateTips(
      role: _selectedRoleForTips!,
      state: widget.gameState,
      player: widget.localPlayer,
    );

    final roleColor = CBColors.fromHex(_selectedRoleForTips!.colorHex);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = _isPhone(context);
    final hPad = phone ? 14.0 : 20.0;
    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.35),
      letterSpacing: 3,
      fontSize: 9,
    );

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
      children: [
        _buildRoleSelector(),
        const SizedBox(height: 20),

        ...tips.where((t) => t.startsWith('🎯')).map((tip) => _buildBriefingCard(tip)),
        const SizedBox(height: 8),

        ...tips.where((t) => t.startsWith('🎯 MVP')).isEmpty
            ? <Widget>[]
            : <Widget>[
                Text("MVP ALLIES & ROLE LINKS", style: labelStyle),
                const SizedBox(height: 10),
                ...tips.where((t) => t.startsWith('🎯 MVP')).map((tip) => _buildBriefingCard(tip)),
                const SizedBox(height: 16),
              ],

        Text("ALLIANCE NETWORK", style: labelStyle),
        const SizedBox(height: 10),
        CBAllianceGraph(
          roles: roleCatalog,
          activeRoleId: _selectedRoleForTips!.id,
          onRoleTap: (role) {
            HapticService.light();
            setState(() => _selectedRoleForTips = role);
          },
        ),
        const SizedBox(height: 24),

        Text("WHAT IF... (${_selectedRoleForTips!.name.toUpperCase()})", style: labelStyle),
        const SizedBox(height: 10),
        ...tips.where((t) => t.contains('WHAT IF')).map((tip) => _buildBriefingCard(tip)),
        const SizedBox(height: 24),

        ...tips.where((t) => t.contains('LIVE:')).isEmpty
            ? <Widget>[]
            : <Widget>[
                Text("LIVE GAME INTEL", style: labelStyle.copyWith(color: roleColor.withValues(alpha: 0.6))),
                const SizedBox(height: 10),
                ...tips.where((t) => t.contains('LIVE:')).map((tip) => _buildBriefingCard(tip)),
                const SizedBox(height: 16),
              ],

        ...tips.where((t) => t.contains('STATUS:')).isEmpty
            ? <Widget>[]
            : <Widget>[
                Text("PERSONAL STATUS", style: labelStyle),
                const SizedBox(height: 10),
                ...tips.where((t) => t.contains('STATUS:')).map((tip) => _buildBriefingCard(tip)),
              ],

        ...tips.where((t) =>
            !t.startsWith('🎯') &&
            !t.contains('WHAT IF') &&
            !t.contains('MVP LINK') &&
            !t.contains('LIVE:') &&
            !t.contains('STATUS:')).isEmpty
            ? <Widget>[]
            : <Widget>[
                const SizedBox(height: 24),
                Text("ADDITIONAL TACTICS", style: labelStyle),
                const SizedBox(height: 10),
                ...tips.where((t) =>
                    !t.startsWith('🎯') &&
                    !t.contains('WHAT IF') &&
                    !t.contains('MVP LINK') &&
                    !t.contains('LIVE:') &&
                    !t.contains('STATUS:')).map((tip) => _buildBriefingCard(tip)),
              ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final color = CBColors.fromHex(_selectedRoleForTips!.colorHex);
    return CBPanel(
      child: InkWell(
        onTap: () {
          HapticService.medium();
          _showRolePickerModal();
        },
        child: Row(
          children: [
            CBRoleAvatar(
              assetPath: _selectedRoleForTips!.assetPath,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedRoleForTips!.name,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TAP TO CHANGE DATA FEED",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "DATA OVERRIDE",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: roleCatalog.length,
                    itemBuilder: (context, index) {
                      final role = roleCatalog[index];
                      final rColor = CBColors.fromHex(role.colorHex);
                      return CBFadeSlide(
                        delay: Duration(milliseconds: 50 + (index * 25)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tileColor: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            leading: CBRoleAvatar(
                              assetPath: role.assetPath,
                              color: rColor,
                              size: 32,
                            ),
                            title: Text(
                              role.name.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: scheme.onSurface,
                                    fontSize: 11,
                                  ),
                            ),
                            onTap: () {
                              HapticService.selection();
                              setState(() => _selectedRoleForTips = role);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBriefingCard(String tip) {
    final isAlert =
        tip.contains("⚠️") || tip.contains("🚨") || tip.contains("🔥");
    final isStatus = tip.contains("💎") || tip.contains("🔇");

    final theme = Theme.of(context);
    final color = isAlert
        ? theme.colorScheme.error
        : (isStatus ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    final scheme = Theme.of(context).colorScheme;
    final phone = _isPhone(context);
    final cardPad = phone ? 14.0 : 20.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_tipIcon(tip), color: color, size: phone ? 18 : 22),
          SizedBox(width: phone ? 10 : 16),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.9),
                    height: 1.5,
                    fontSize: phone ? 13 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _tipIcon(String tip) {
    if (tip.contains("⚠️") || tip.contains("🚨")) {
      return Icons.warning_amber_rounded;
    }
    if (tip.contains("🔥")) return Icons.local_fire_department_rounded;
    if (tip.contains("🛡️")) return Icons.shield_rounded;
    if (tip.contains("💎")) return Icons.diamond_rounded;
    if (tip.contains("🔇")) return Icons.mic_off_rounded;
    return Icons.lightbulb_outline_rounded;
  }
}

class _GuideStrategyGenerator {
  _GuideStrategyGenerator._();

  static List<String> generateTips({
    required Role role,
    GameState? state,
    Player? player,
  }) {
    final tips = <String>[
      _baseTip(role.id),
      ..._whatIfScenarios(role.id),
      ..._mvpAdvice(role.id),
    ];

    if (state != null) {
      tips.addAll(_dynamicGameTips(role, state));
    }

    if (player != null) {
      tips.addAll(_personalStatusTips(player, state));
    }

    return tips;
  }

  // ── Base strategic identity for each role ─────────────────────────────

  static String _baseTip(String roleId) => switch (roleId) {
    RoleIds.dealer =>
      '🎯 CORE STRATEGY: Coordinate kills to maximize chaos. Target investigators first (Bouncer, Bartender), then protectors (Medic, Sober). Frame suspicious innocents during the day — never be the first to accuse without evidence.',
    RoleIds.whore =>
      '🎯 CORE STRATEGY: Your Scapegoat is your insurance policy. Choose someone robust who will survive multiple rounds. Save your vote deflection for when exile is guaranteed — timing is everything.',
    RoleIds.silverFox =>
      '🎯 CORE STRATEGY: Your nightly alibi corrupts investigations. Shield fellow Dealers from the Bouncer or grant alibis to innocents to seem trustworthy. Vary your targets — a pattern is your downfall.',
    RoleIds.bouncer =>
      '🎯 CORE STRATEGY: You are the Club\'s primary investigator. Check the most influential players first — Dealers control conversations. Breadcrumb results to trusted allies before going public.',
    RoleIds.medic =>
      '🎯 CORE STRATEGY: Your first decision (Protect vs Revive) shapes the entire game. PROTECT: Shield the Bouncer once claimed. REVIVE: Wait for a confirmed power role death. Never waste either on uncertain targets.',
    RoleIds.roofi =>
      '🎯 CORE STRATEGY: Silence is your weapon. Paralyse suspected Dealers to block their night kill, or silence vocal manipulators to neutralize their daytime influence. Track who had no night report after you acted.',
    RoleIds.sober =>
      '🎯 CORE STRATEGY: Sending players home is both shield and sword. Protect Bouncer/Medic on dangerous nights, or block suspected Dealer kills by sending their likely target home. Coordinate with Medic to avoid overlapping.',
    RoleIds.wallflower =>
      '🎯 CORE STRATEGY: You are the only eyewitness. Observe silently during murder phases, memorize faces, and wait for the critical moment to reveal proof. One well-timed testimony can win the game.',
    RoleIds.allyCat =>
      '🎯 CORE STRATEGY: You are the Bouncer\'s surveillance partner with 9 lives as a shield. Draw Dealer fire to protect fragile roles. Your votes are your primary communication — use them to accuse boldly.',
    RoleIds.minor =>
      '🎯 CORE STRATEGY: You are immune to Dealer kills until the Bouncer IDs you. Use this invisible shield to be aggressive in discussions and lead vote pushes without fear of night retaliation.',
    RoleIds.partyAnimal =>
      '🎯 CORE STRATEGY: No ability means no risk of exposure. Be the loudest voice against Dealers. Track voting patterns, ask pointed questions, and build coalitions. Your freedom is your weapon.',
    RoleIds.seasonedDrinker =>
      '🎯 CORE STRATEGY: You are the team\'s tank with lives equal to the Dealer count. Be loud, draw kills, and use each lost life as proof of Dealer activity. Shield power roles by being a juicier target.',
    RoleIds.lightweight =>
      '🎯 CORE STRATEGY: Survival depends on vigilance. Read your taboo list THREE times before every message. Use descriptions instead of names. Anyone baiting you into saying a taboo is likely a Dealer.',
    RoleIds.teaSpiller =>
      '🎯 CORE STRATEGY: Your death reveals a voter\'s role. This deters Dealer votes against you — consider claiming it publicly. If you\'re going down, ensure Dealers voted for you to maximize the reveal value.',
    RoleIds.predator =>
      '🎯 CORE STRATEGY: Your revenge kill is your trump card. Keep it secret. Build a mental kill list of confirmed Dealers so your death always takes out a high-value target. Reveal only when leverage is needed.',
    RoleIds.dramaQueen =>
      '🎯 CORE STRATEGY: Your death randomly swaps two roles. This chaos deters both Dealer kills and Club votes. Claim it publicly to become untouchable — nobody wants unpredictable role shuffles.',
    RoleIds.bartender =>
      '🎯 CORE STRATEGY: Check one suspected Dealer against one confirmed innocent. If misaligned, you have a lead. Build a web of connections and cross-reference with Bouncer results for double confirmation.',
    RoleIds.messyBitch =>
      '🎯 CORE STRATEGY: Solo win condition — rumour every living player. Prioritize players on the winning team (they survive longest). Play both sides, extend the game, and never reveal your true goal.',
    RoleIds.clubManager =>
      '🎯 CORE STRATEGY: Survival is your only win condition. View role cards each night to identify the winning team, then align with them. Feed true intel to earn protection. Pivot freely — loyalty is optional.',
    RoleIds.clinger =>
      '🎯 CORE STRATEGY: Your partner is your lifeline. Choose someone durable (Minor, Seasoned Drinker, Medic). Follow their lead, protect them with social capital, and if freed as Attack Dog, use your kill on a confirmed Dealer.',
    RoleIds.secondWind =>
      '🎯 CORE STRATEGY: Play as a genuine Party Animal until triggered. If Dealers attempt to kill you, you survive — then negotiate conversion. If converted, leverage your established trust to be the ultimate mole.',
    RoleIds.creep =>
      '🎯 CORE STRATEGY: Target selection on Night 0 defines your entire game. Pick someone durable and study their behaviour. When they die, inherit their role seamlessly — delays and confusion will expose you.',
    _ =>
      '🎯 CORE STRATEGY: Use your vote as your primary weapon. Track voting patterns, challenge suspicious silence, and build trust through consistent reads.',
  };

  // ── "What If" scenario tips per role ──────────────────────────────────

  static List<String> _whatIfScenarios(String roleId) => switch (roleId) {
    RoleIds.dealer => [
      '🛡️ WHAT IF I\'M INVESTIGATED? The Bouncer checks one player per night. If you feel heat, coordinate with Silver Fox for an alibi or have your team kill the Bouncer before they report.',
      '⚠️ WHAT IF I\'M THE LAST DEALER? Play ultra-conservatively. Vote with the majority, never lead accusations, and target quiet Party Animals at night. Your survival IS the win condition.',
      '🔥 WHAT IF THE MEDIC IS PROTECTING MY TARGET? Switch targets. Kill someone unexpected to waste the Medic\'s prediction. Or target the Medic directly to remove the safety net.',
    ],
    RoleIds.whore => [
      '🛡️ WHAT IF MY SCAPEGOAT DIES BEFORE I USE DEFLECTION? You lose your ability permanently. Choose the most durable, least suspicious player as your scapegoat — Medic or Seasoned Drinker are ideal.',
      '⚠️ WHAT IF I\'M ABOUT TO BE VOTED OUT? This is your moment. Deflect the vote to someone the Club was already suspicious of to make it look like justice was served.',
      '🔥 WHAT IF THE CLUB KNOWS ABOUT DEFLECTION? Pre-seed suspicion against your scapegoat days in advance so the redirect feels natural, not forced.',
    ],
    RoleIds.silverFox => [
      '🛡️ WHAT IF THE BOUNCER CHECKS MY ALIBI TARGET? Your alibi may corrupt their result, making an innocent look suspicious or a Dealer look clean. Track Bouncer activity to time your alibis.',
      '⚠️ WHAT IF MY PATTERN IS NOTICED? Break the pattern immediately — alibi an innocent to throw off analysis. Never alibi the same player twice.',
      '🔥 WHAT IF THE BARTENDER CROSS-CHECKS? Bartender alignment checks work differently. Your alibi may not fully protect against their method — prioritize avoiding Bouncer checks.',
    ],
    RoleIds.bouncer => [
      '🛡️ WHAT IF I FIND A DEALER? Don\'t reveal immediately — sit on the info to observe who they coordinate with. One Dealer leads to another.',
      '⚠️ WHAT IF I\'M BLOCKED BY ROOFI? Your check won\'t go through. Note the blank night and deduce who might have Roofied you — that player likely wanted to protect a Dealer you were about to check.',
      '🔥 WHAT IF SILVER FOX CORRUPTS MY RESULTS? Cross-reference with the Bartender if available. If your results contradict other evidence, Silver Fox is active and shielding Dealers.',
    ],
    RoleIds.medic => [
      '🛡️ WHAT IF THE BOUNCER HASN\'T CLAIMED? Protect yourself Night 1 (if allowed), then vary targets until the Bouncer reveals. Dealers kill investigators first.',
      '⚠️ WHAT IF I\'M IN REVIVE MODE AND NO ONE IMPORTANT DIES? Don\'t wait past Day 3 — better to revive someone decent than die with the token unused.',
      '🔥 WHAT IF DEALERS TARGET ME? You cannot self-protect in most modes. Coordinate with the Sober to be sent home on dangerous nights.',
    ],
    RoleIds.roofi => [
      '🛡️ WHAT IF I SILENCE THE WRONG PERSON? Track your results — if you silenced someone and a kill still happened, they\'re NOT the Dealer. Share this deduction.',
      '⚠️ WHAT IF I SILENCE THE BOUNCER BY ACCIDENT? Their investigation is blocked for the night. Coordinate targets with known Party Animal roles to avoid friendly fire.',
      '🔥 WHAT IF THERE\'S ONLY ONE DEALER LEFT? Silencing them blocks the night kill entirely. If you can identify them, this is a guaranteed safe night for the Club.',
    ],
    RoleIds.sober => [
      '🛡️ WHAT IF I SEND HOME THE WRONG PERSON? Their night action is frozen too. If the kill still happens, you know you didn\'t block the Dealer — useful deduction data.',
      '⚠️ WHAT IF THE MEDIC IS ALSO PROTECTING? You\'re doubling up. Coordinate to cover different players — two overlapping protections waste a slot.',
      '🔥 WHAT IF I SEND HOME A DEALER? They can\'t commit the night kill. If someone was supposed to die and didn\'t, you may have accidentally blocked the Dealer. Note who you sent home.',
    ],
    RoleIds.wallflower => [
      '🛡️ WHAT IF I SEE THE MURDER BUT CAN\'T IDENTIFY THE KILLER? Partial info is still valuable. Note positions, movements, and timing — you can narrow suspects without a full ID.',
      '⚠️ WHAT IF I\'M KILLED BEFORE I CAN REVEAL? Leave breadcrumbs during the day — subtle hints that don\'t fully expose you but give allies a thread to pull if you die.',
      '🔥 WHAT IF MY TESTIMONY IS CONTRADICTED? Someone is lying — either you or them. If you\'re certain in your witness, push hard. Dealers will try to discredit the Wallflower.',
    ],
    RoleIds.allyCat => [
      '🛡️ WHAT IF THE BOUNCER DIES? Your surveillance intel stops. Pivot to pure voting strategy — your 9 lives still make you a powerful vote presence.',
      '⚠️ WHAT IF I\'M VOTE-TARGETED? Your lives only protect against Dealer kills. Votes exile you normally. Defend aggressively with meows and hope allies understand your urgency.',
      '🔥 WHAT IF THE BOUNCER FINDS A DEALER? Immediately vote for that player. Your confident early vote signals to the Club that you have corroborating info.',
    ],
    RoleIds.minor => [
      '🛡️ WHAT IF THE BOUNCER CHECKS ME? Your immunity to Dealer kills is removed. Once ID\'d, you become a regular target — adapt from aggressive to cautious overnight.',
      '⚠️ WHAT IF I\'M VOTE-TARGETED? Your immunity only blocks DEALER kills. Votes, Predator revenge, and Lightweight taboo still work on you. Defend yourself socially.',
      '🔥 WHAT IF DEALERS KEEP TRYING TO KILL ME? Each failed attempt wastes their night action. Let them — you\'re a kill sponge protecting actual fragile roles.',
    ],
    RoleIds.partyAnimal => [
      '🛡️ WHAT IF I\'M ACCUSED? You have nothing to hide. Claim Party Animal confidently — it\'s verifiable and frees power roles from claiming early.',
      '⚠️ WHAT IF I SEE VOTING PATTERNS? Track everything. Two players who always vote together may be coordinating Dealers. Two who never vote each other are potential allies.',
      '🔥 WHAT IF THE CLUB IS LOSING? Rally the remaining players. Your lack of ability means you\'re the safest leader — no one gains from your death.',
    ],
    RoleIds.seasonedDrinker => [
      '🛡️ WHAT IF I LOSE ALL MY LIVES? You\'re now a regular Party Animal. Adjust from tank play to careful survival immediately.',
      '⚠️ WHAT IF DEALERS AVOID ME? Your lives are wasted on a player nobody attacks. Be louder, more aggressive — make yourself a target worth spending kills on.',
      '🔥 WHAT IF I NOTICE A LIFE LOST? Announce it — "I was targeted last night." This confirms Dealer activity and puts pressure on the investigation.',
    ],
    RoleIds.lightweight => [
      '🛡️ WHAT IF SOMEONE BAITS MY TABOO? They\'re likely a Dealer trying to kill you without using a night action. Call it out immediately — it\'s suspicious behaviour.',
      '⚠️ WHAT IF MY TABOO LIST IS HUGE? Use pronouns, descriptions, and player positions instead of names. "The player who voted first" is safer than any name.',
      '🔥 WHAT IF I ACCIDENTALLY SAY A TABOO? You die instantly. There\'s no recovery. Always triple-check and type slowly.',
    ],
    RoleIds.teaSpiller => [
      '🛡️ WHAT IF DEALERS AVOID VOTING ME? Your threat is working. Use this immunity to be an aggressive vote leader — they can\'t pile on without risking exposure.',
      '⚠️ WHAT IF I\'M NIGHT-KILLED INSTEAD? Your ability only triggers on VOTES. Dealers will try to kill you at night to avoid it. Seek Medic protection.',
      '🔥 WHAT IF THE REVEAL TARGETS AN INNOCENT? It\'s random. But even revealing an innocent\'s role gives the Club confirmation data.',
    ],
    RoleIds.predator => [
      '🛡️ WHAT IF I\'M ABOUT TO DIE? Choose your revenge target wisely. A confirmed Dealer is ideal — your death trades 1-for-1 in the Club\'s favour.',
      '⚠️ WHAT IF DEALERS KNOW I\'M THE PREDATOR? They\'ll try to vote-exile you to control the timing. Keep your role hidden as long as possible.',
      '🔥 WHAT IF I CAN\'T IDENTIFY A DEALER? Target the player who pushed hardest for your exile. Statistically, Dealers drive vote pushes.',
    ],
    RoleIds.dramaQueen => [
      '🛡️ WHAT IF MY SWAP HURTS THE CLUB? The swap is random — you can\'t control it. This is why staying alive is better than hoping for a favourable swap.',
      '⚠️ WHAT IF DEALERS WANT THE CHAOS? If Dealers are ahead, a random swap might benefit them. In that case, stay alive rather than triggering it.',
      '🔥 WHAT IF I CLAIM DRAMA QUEEN? Most players will avoid killing you. Use this untouchable status to be an aggressive investigator.',
    ],
    RoleIds.bartender => [
      '🛡️ WHAT IF MY RESULTS CONFLICT WITH THE BOUNCER? Silver Fox alibis are corrupting one of you. Compare notes to find the manipulator.',
      '⚠️ WHAT IF I CHECK TWO INNOCENTS? Wasted action. Always include one suspected player in your pair to generate actionable data.',
      '🔥 WHAT IF I FIND TWO ALIGNED DEALERS? You\'ve struck gold. Cross-reference with voting patterns and reveal when you can seal both exiles.',
    ],
    RoleIds.messyBitch => [
      '🛡️ WHAT IF BOTH TEAMS DISCOVER MY GOAL? They\'ll exile you immediately. Keep your solo win condition secret and blame rumours on other mechanics.',
      '⚠️ WHAT IF PLAYERS DIE BEFORE I RUMOUR THEM? Fewer living players means fewer targets. Prioritize rumouring survivors on the winning side.',
      '🔥 WHAT IF I\'M CLOSE TO WINNING? Target the last few un-rumoured players urgently. Consider helping the weaker team survive to buy yourself more nights.',
    ],
    RoleIds.clubManager => [
      '🛡️ WHAT IF BOTH TEAMS SUSPECT ME? Stay useful to whoever is winning. Feed accurate intel to earn protection and blend with the majority.',
      '⚠️ WHAT IF THE WINNING TEAM SHIFTS? Pivot immediately. Your loyalty is to survival, not to any alliance. Feed intel to the new frontrunners.',
      '🔥 WHAT IF I KNOW EVERYONE\'S ROLE? Use this power broker position carefully. Reveal just enough to seem valuable without becoming a threat to eliminate.',
    ],
    RoleIds.clinger => [
      '🛡️ WHAT IF MY PARTNER IS ACCUSED? Reveal your Clinger status to save them — the Club won\'t want a 2-for-1 exile unless your partner is confirmed evil.',
      '⚠️ WHAT IF MY PARTNER IS A DEALER? Accept the situation and play to survive. Your vote is locked to theirs, which may out you — plan for it.',
      '🔥 WHAT IF I\'M FREED AS ATTACK DOG? You gain independence and a kill. Use it on the most confirmed Dealer — this is your one shot at maximum impact.',
    ],
    RoleIds.secondWind => [
      '🛡️ WHAT IF DEALERS CHOOSE TO EXECUTE ME? You die permanently. Negotiate hard for conversion — emphasize your established trust within the Club as an asset.',
      '⚠️ WHAT IF I\'M CONVERTED? Your win condition flips to Club Staff instantly. Use your deep trust network to misdirect votes and protect your new team.',
      '🔥 WHAT IF I RESIST CONVERSION? Use all the intel gathered during the negotiation window to expose Dealer identities to the Club.',
    ],
    RoleIds.creep => [
      '🛡️ WHAT IF MY TARGET IS KILLED EARLY? You inherit their role immediately. Be ready to use the ability seamlessly — any hesitation exposes you.',
      '⚠️ WHAT IF MY TARGET IS A DEALER? You adopt Club Staff alliance. Lean into it — you now win with the Dealers and have insider knowledge.',
      '🔥 WHAT IF NOBODY KNOWS MY TARGET? Perfect. Study them silently, adopt their behaviour patterns, and when inheritance triggers, nobody will notice the switch.',
    ],
    _ => [
      '📊 WHAT IF I\'M ACCUSED? Stay calm. Provide your logic, cite your voting history, and challenge the accuser\'s evidence.',
      '🛡️ WHAT IF THE CLUB IS LOSING? Rally around confirmed info. Push for data sharing and coordinated votes rather than panic decisions.',
    ],
  };

  // ── MVP role relationship advice ──────────────────────────────────────

  static List<String> _mvpAdvice(String roleId) => switch (roleId) {
    RoleIds.allyCat => [
      '🎯 MVP LINK → THE BOUNCER: Your entire investigative value comes from watching them work. Keep the Bouncer alive at all costs — tank kills, rally votes to protect them, and use your meows to validate their findings.',
    ],
    RoleIds.bouncer => [
      '🎯 MVP LINK → THE MEDIC: Once you claim, the Medic should protect you every night. Coordinate secretly to ensure your investigations continue uninterrupted.',
      '🎯 MVP LINK → THE ALLY CAT: They witness your checks. If they vote for someone you just checked, it corroborates your findings without words.',
    ],
    RoleIds.medic => [
      '🎯 MVP LINK → THE BOUNCER: Your #1 protection target. A living Bouncer who is investigating is the Club\'s greatest asset. Shield them relentlessly.',
      '🎯 MVP LINK → THE WALLFLOWER: Secondary protection priority. Their eyewitness testimony is irreplaceable evidence.',
    ],
    RoleIds.wallflower => [
      '🎯 MVP LINK → THE BOUNCER: Cross-reference your murder witness info with their ID check results. Together, you can triangulate Dealer identities with near certainty.',
      '🎯 MVP LINK → THE MEDIC: Ask for protection subtly. Your death removes the only eyewitness — Dealers will target you once you reveal.',
    ],
    RoleIds.roofi => [
      '🎯 MVP LINK → THE BOUNCER: Coordinate targets — silence someone the Bouncer isn\'t checking to maximize coverage. If you block a kill, the Bouncer can confirm who you silenced.',
      '🎯 MVP LINK → THE MEDIC: If the Medic can\'t protect a target, you can silence the attacker instead. Complementary protection coverage.',
    ],
    RoleIds.sober => [
      '🎯 MVP LINK → THE MEDIC: Divide protection duty. You send home one player, Medic protects another. Never overlap on the same target.',
      '🎯 MVP LINK → THE BOUNCER: Send the Bouncer home on nights they\'re not investigating to guarantee their survival without blocking their action.',
    ],
    RoleIds.bartender => [
      '🎯 MVP LINK → THE BOUNCER: Cross-reference your alignment checks with their ID checks. Matching data is a conviction; conflicting data reveals Silver Fox interference.',
    ],
    RoleIds.dealer => [
      '🎯 MVP LINK → THE SILVER FOX: Their alibis protect you from investigation. Coordinate nightly — when the Bouncer is closing in, the Silver Fox is your shield.',
      '🎯 MVP LINK → THE WHORE: Their vote deflection is your emergency exit. Keep the Whore alive as long as possible — they buy you one free exile escape.',
    ],
    RoleIds.whore => [
      '🎯 MVP LINK → THE DEALER: You exist to protect the team. Your deflection buys the Dealers one extra round. Coordinate your scapegoat choice with their kill strategy.',
    ],
    RoleIds.silverFox => [
      '🎯 MVP LINK → THE DEALER: Your alibis corrupt Bouncer checks on Dealers. Time your alibis to shield whichever Dealer is most at risk of investigation that night.',
    ],
    RoleIds.seasonedDrinker => [
      '🎯 MVP LINK → THE MEDIC: Together you\'re nearly unkillable. Let the Medic protect fragile roles while you absorb Dealer kills with your extra lives.',
    ],
    RoleIds.minor => [
      '🎯 MVP LINK → THE BOUNCER: Secretly hope they DON\'T check you — your immunity lasts only until they do. If they haven\'t claimed checking you, you\'re still invincible at night.',
    ],
    RoleIds.clinger => [
      '🎯 MVP LINK → YOUR CHOSEN PARTNER: Literally — if they die, you die. Choose wisely. Minor, Seasoned Drinker, or Medic-protected players are safest bets.',
    ],
    RoleIds.messyBitch => [
      '🎯 MVP LINK → NOBODY: You win solo. Both teams are obstacles. Play both sides, extend the game, and rumour your way to victory while everyone else fights.',
    ],
    RoleIds.clubManager => [
      '🎯 MVP LINK → THE WINNING TEAM: Whoever is ahead is your temporary ally. Feed them intel to earn protection, then pivot if the tide turns.',
    ],
    _ => [],
  };

  // ── Dynamic game-state tips (Host-side GameState) ─────────────────────

  static List<String> _dynamicGameTips(Role role, GameState state) {
    final tips = <String>[];
    final alive = state.players.where((p) => p.isAlive).toList();

    final bouncerAlive = alive.any((p) => p.role.id == RoleIds.bouncer);
    final medicAlive = alive.any((p) => p.role.id == RoleIds.medic);
    final roofiAlive = alive.any((p) => p.role.id == RoleIds.roofi);
    final staffAlive = alive.where((p) => p.role.alliance == Team.clubStaff).length;
    final townAlive = alive.where((p) => p.role.alliance != Team.clubStaff).length;

    if (role.alliance == Team.clubStaff) {
      if (bouncerAlive) {
        tips.add('⚠️ LIVE: The Bouncer is ALIVE and investigating. Blend in carefully — every check narrows the suspect pool.');
      } else {
        tips.add('🔥 LIVE: The Bouncer is DEAD. No more ID checks — you have room for bolder plays.');
      }
      if (!medicAlive) {
        tips.add('🔥 LIVE: The Medic is neutralized. Every kill sticks — no saves or resurrections.');
      }
      if (staffAlive == 1) {
        tips.add('🚨 LIVE: You are the LAST Dealer alive. Play ultra-conservatively — one mistake ends it.');
      }
      if (staffAlive > 0 && staffAlive >= townAlive - 1) {
        tips.add('🔥 LIVE: You\'re approaching PARITY. One more Party Animal elimination and you WIN.');
      }
    } else {
      if (!bouncerAlive) {
        tips.add('⚠️ LIVE: Your investigator is down. Rely on social reads and voting patterns.');
      }
      if (!medicAlive) {
        tips.add('⚠️ LIVE: No Medic protection. Every death is permanent — vote carefully.');
      }
      if (staffAlive > 0 && townAlive <= staffAlive + 2) {
        tips.add('🚨 LIVE: Dealers are close to majority! You MUST exile a Dealer today or lose.');
      }
    }

    if (roofiAlive && role.id != RoleIds.roofi) {
      if (staffAlive == 1) {
        tips.add('🛡️ LIVE: If Roofi silences the last Dealer tonight, the kill is completely blocked.');
      }
    }

    if (alive.length <= 4) {
      tips.add('🚨 LIVE: ENDGAME — ${alive.length} players remain. Every vote is decisive.');
    }

    return tips;
  }

  // ── Personal status tips ──────────────────────────────────────────────

  static List<String> _personalStatusTips(Player player, GameState? state) {
    final tips = <String>[];
    if (player.lives > 1) {
      tips.add('💎 STATUS: You have ${player.lives} active lives. Use your durability to draw fire from fragile power roles.');
    }
    if (state != null && player.silencedDay == state.dayCount) {
      tips.add('🔇 STATUS: You were SILENCED by Roofi. Your night action was blocked — adapt your strategy.');
    }
    if (player.hasRumour) {
      tips.add('📰 STATUS: A rumour has been spread about you. This is public knowledge — gauge who reacts suspiciously.');
    }
    return tips;
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSubItem;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.symmetric(
              vertical: isSubItem ? 4 : 8, horizontal: isSubItem ? 16 : 12),
          padding: EdgeInsets.symmetric(vertical: isSubItem ? 8 : 12),
          decoration: isActive
              ? BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: isSubItem ? 18 : 24,
                shadows: isActive
                    ? [Shadow(color: activeColor, blurRadius: 8)]
                    : null,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? activeColor : scheme.onSurfaceVariant.withValues(alpha: 0.45);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: isActive
                ? BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.25),
                    ),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
