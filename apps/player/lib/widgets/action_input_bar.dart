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
      HapticService.selection();
      widget.onSendChat(text);
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVoting = widget.gameState.currentStep?.isVote ?? false;
    final isNightAction = _isMyNightAction();
    final player = widget.gameState.players.firstWhere(
      (p) => p.id == widget.playerId,
      orElse: () => PlayerSnapshot(
        id: widget.playerId,
        name: '',
        roleId: '',
        roleName: '',
      ),
    );
    final isDead = !player.isAlive;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDead && (isVoting || isNightAction)) ...[
              CBFadeSlide(
                child: CBPrimaryButton(
                  label: isVoting ? 'INITIATE VOTE' : 'EXECUTE MISSION',
                  icon:
                      isVoting ? Icons.how_to_vote_rounded : Icons.bolt_rounded,
                  onPressed:
                      isVoting ? widget.onVotePressed : widget.onActionPressed,
                  backgroundColor: isVoting ? scheme.secondary : scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: CBTextField(
                    controller: _chatController,
                    hintText: 'SECURE CHANNEL...',
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleSend,
                  icon: Icon(Icons.send_rounded, color: scheme.primary),
                  tooltip: 'Send Transmission',
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(CBSpace.x3),
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

    final me = widget.gameState.players.firstWhere(
      (p) => p.id == widget.playerId,
      orElse: () => PlayerSnapshot(
        id: widget.playerId,
        name: '',
        roleId: '',
        roleName: '',
      ),
    );

    if (step.roleId != null && step.roleId == me.roleId) return true;

    return false;
  }
}
