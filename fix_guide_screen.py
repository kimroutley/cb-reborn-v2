import os

filepath = 'packages/cb_theme/lib/src/screens/guide_screen.dart'

with open(filepath, 'r') as f:
    lines = f.readlines()

# It seems there was a corruption around line 614 where a CBSlidingPanel might have been pasted incorrectly
# or some widget code was left dangling outside a method.
# Based on the read output, lines 614-645 seem to be the issue.
# However, looking at the previous  output (lines 600-650), I don't see the corruption in the provided snippet.
# Wait, the  output I got looks clean?
# Let me re-read the specific lines reported in the error log: 614-645.
# Ah, I read lines 600-650 and 160-175 and 60-70.
# The error said:
# lib/src/screens/guide_screen.dart:614:10 • expected_token
# lib/src/screens/guide_screen.dart:615:7 • expected_token
# lib/src/screens/guide_screen.dart:616:7 • prefer_typing_uninitialized_variables

# Let's read the file content again carefully from the  output.
# The output for lines 600-650 shows:
# 600:           '🚨 TACTIC: Vote for your own partner early if the heat is too high—it builds massive "innocent" credit.'
# 601:         ];
# ...
# 648: class _RailItem extends StatelessWidget {

# It seems the file I read is DIFFERENT from what the CI saw, or I missed something.
# Wait, the CI log says:
# error • The method 'CBSlidingPanel' isn't defined for the type '_CBGuideScreenState' • lib/src/screens/guide_screen.dart:66:11 • undefined_method
# This suggests CBSlidingPanel is being used as a method but it is a Widget class.
# And:
# error • The named parameter 'activeCategoryIndex' isn't defined • lib/src/screens/guide_screen.dart:168:11
# error • The named parameter 'onCategoryChanged' isn't defined • lib/src/screens/guide_screen.dart:169:11

# Let's check imports.  should be imported. It's likely in .
# Let's check  usage at 168.

# I will assume the file on disk is "correct" in structure but has some issues.
# But wait, if the file I read is clean, maybe the CI is running on an older version or I am looking at a version that doesn't have the error?
# No, I am editing the current codebase.

# Let's look at  in  or wherever it is defined.
# And check  definition.
