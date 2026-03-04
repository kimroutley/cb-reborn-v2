import sys

with open('packages/cb_theme/lib/src/screens/guide_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace state vars
content = content.replace(
'''  int _activeMainIndex = 0; // 0: Handbook, 1: Operatives, 2: Strategy
  int _activeHandbookCategoryIndex = 0;''',
'''  int _activeHandbookCategoryIndex = 0;'''
)

# 2. Replace build method and delete bottom/rail/active
build_method_start = '''  @override
  Widget build(BuildContext context) {'''

operatives_tab_start = '''  // ── Tab 2: Operatives (Interactive Browser) ──'''

new_build_method = '''  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: CBPrismScaffold(
        title: "THE BLACKBOOK",
        drawer: widget.drawer,
        appBarBottom: TabBar(
          dividerColor: CBColors.transparent,
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'MANUAL', icon: Icon(Icons.menu_book_rounded)),
            Tab(text: 'OPERATIVES', icon: Icon(Icons.groups_rounded)),
            Tab(text: 'INTEL', icon: Icon(Icons.psychology_rounded)),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                // Tab 1: Manual
                Column(
                  children: [
                    _buildMobileSubNavigation(scheme),
                    Expanded(
                      child: CBIndexedHandbook(
                        gameState: widget.gameState,
                        activeCategoryIndex: _activeHandbookCategoryIndex,
                        onCategoryChanged: (index) =>
                            setState(() => _activeHandbookCategoryIndex = index),
                      ),
                    ),
                  ],
                ),
                // Tab 2: Operatives
                _buildOperativesTab(),
                // Tab 3: Intel
                _buildIntelTab(),
              ],
            ),

            // ── SLIDING DETAILS PANEL ──
            CBSlidingPanel(
              isOpen: _isPanelOpen,
              onClose: () => setState(() => _isPanelOpen = false),
              title: _selectedDossierRole?.name ?? "DATA FILE",
              width: 450,
              child: _selectedDossierRole != null
                  ? SingleChildScrollView(
                      child:
                          _buildOperativeDetails(context, _selectedDossierRole!),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSubNavigation(ColorScheme scheme) {
    final icons = [
      Icons.nightlife_rounded,
      Icons.loop_rounded,
      Icons.groups_rounded,
      Icons.wine_bar_rounded,
      Icons.settings_remote_rounded,
      Icons.smartphone_rounded,
    ];
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: 6,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final isActive = _activeHandbookCategoryIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(icons[index]),
                color: isActive ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                onPressed: () {
                  HapticService.light();
                  setState(() => _activeHandbookCategoryIndex = index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

'''

part1 = content.split(build_method_start)[0]
part2 = content.split(operatives_tab_start)[1]

content = part1 + new_build_method + operatives_tab_start + part2

# 3. Remove _RailItem
rail_item_start = '''class _RailItem extends StatelessWidget {'''
content = content.split(rail_item_start)[0]

with open('packages/cb_theme/lib/src/screens/guide_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
