import re

file_path = 'packages/cb_logic/lib/src/persistence/persistence_service.dart'

with open(file_path, 'r') as f:
    content = f.read()

# 1. Add import
if "import 'role_award_calculator.dart';" not in content:
    content = content.replace("import 'dart:isolate';", "import 'dart:isolate';\nimport 'role_award_calculator.dart';")

# 2. Replace rebuildRoleAwardProgresses
old_method_pattern = re.compile(r'  Future<List<PlayerRoleAwardProgress>> rebuildRoleAwardProgresses\(\) async \{.*?return rebuilt;\n  \}', re.DOTALL)

new_method = """  Future<List<PlayerRoleAwardProgress>> rebuildRoleAwardProgresses() async {
    await clearRoleAwardProgresses();
    final records = loadGameRecords();

    if (records.isEmpty) {
      return const <PlayerRoleAwardProgress>[];
    }

    final rebuilt = await Isolate.run(() => calculateRoleAwardProgress(records));

    final batch = <String, String>{};
    for (final progress in rebuilt) {
      batch[_awardProgressKey(progress.playerKey, progress.awardId)] = jsonEncode(progress.toJson());
    }
    await _recordsBox.putAll(batch);

    return rebuilt;
  }"""

content = old_method_pattern.sub(new_method, content)

# 3. Remove extracted methods
methods_to_remove = [
    r'  int _minimumForRule\(Map<String, dynamic> unlockRule\) \{.*?return 1;\n  \}',
    r'  int _metricValueForRule\(\n    _RoleUsageStats stats,\n    Map<String, dynamic> unlockRule,\n  \) \{.*?return stats\.gamesPlayed;\n    \}\n  \}',
    r'  Map<String, Map<String, _RoleUsageStats>> _buildRoleStatsByPlayer\(\n    List<GameRecord> records,\n  \) \{.*?return roleStatsByPlayer;\n  \}'
]

for method in methods_to_remove:
    content = re.sub(method, '', content, flags=re.DOTALL)

# 4. Remove _RoleUsageStats class
class_pattern = re.compile(r'class _RoleUsageStats \{.*?\}\n\}', re.DOTALL)
# Wait, the class ends with } and the file ends? Or is it nested?
# It's at the end of the file.
class_pattern = re.compile(r'class _RoleUsageStats \{.*?\}\n', re.DOTALL)
content = class_pattern.sub('', content)

# Clean up extra newlines
content = re.sub(r'\n{3,}', '\n\n', content)

with open(file_path, 'w') as f:
    f.write(content)

print("File updated successfully.")
