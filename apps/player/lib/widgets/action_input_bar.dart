import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../player_bridge.dart';

class ActionInputBar extends StatefulWidget {
  final PlayerGameState gameState;
  final String playerId;
  final VoidCallback onVotePressed;
  final VoidCallback onActionPressed;
  final Function(String) onSendChat;

  const ActionInputBar({
    super.key,
    required this.gameState,
    required this.playerId,
    required this.onVotePressed,
    required this.onActionPressed,
    required this.onSendChat,
  });

  @override
  State<ActionInputBar> createState() => _ActionInputBarState();
}

class _ActionInputBarState extends State<ActionInputBar> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendChat(text);
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVoting = widget.gameState.currentStep?.isVote ?? false;
    final isNightAction = _isMyNightAction();
    final isDead = !widget.gameState.players
        .firstWhere((p) => p.id == widget.playerId,
            orElse: () => PlayerSnapshot(
                  id: widget.playerId,
                  name: '',
                  roleId: '',
                  roleName: '',
                ))
        .isAlive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: scheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action Button (if applicable)
            if (!isDead && (isVoting || isNightAction)) ...[
              SizedBox(
                width: double.infinity,
                child: CBPrimaryButton(
                  label: isVoting ? 'CAST VOTE' : 'PERFORM ACTION',
                  onPressed:
                      isVoting ? widget.onVotePressed : widget.onActionPressed,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Chat Input
            Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _chatController,
                    hintText: 'SECURE CHANNEL...',
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send action',
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send),
                  color: scheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary.withValues(alpha: 0.1),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isMyNightAction() {
    final step = widget.gameState.currentStep;
    if (step == null) return false;

    // Check if step is for my role
    final me = widget.gameState.players.firstWhere(
      (p) => p.id == widget.playerId,
      orElse: () => PlayerSnapshot(
        id: widget.playerId,
        name: '',
        roleId: '',
        roleName: '',
      ),
    );

    // Simple check: does the step roleId match my roleId?
    // Or is it a generic action?
    // Logic from legacy GameScreen needed here.
    // Usually step.roleId == me.roleId
    if (step.roleId != null && step.roleId == me.roleId) return true;

    return false;
  }
}
