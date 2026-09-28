import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../services/member_area_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../widgets/cooperative/poll_card.dart';

/// Enquetes da associação: votar nas abertas (uma vez, voto secreto) e ver o resultado das outras
class MemberPollsView extends StatefulWidget {
  const MemberPollsView({super.key});

  @override
  State<MemberPollsView> createState() => _MemberPollsViewState();
}

class _MemberPollsViewState extends State<MemberPollsView> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final service = context.read<MemberAreaService>();
    return AppLoadView<List<Poll>>(
      key: ValueKey(_version),
      load: service.fetchPolls,
      builder: (context, polls, reload) => AppPageListView(
        top: 8,
        maxWidth: 720,
        children: [
          if (polls.isEmpty)
            const AppEmptyState(icon: Icons.how_to_vote_outlined, message: 'Nenhuma enquete por enquanto.'),
          for (final poll in polls) ...[
            PollCard(
              poll: poll,
              onVote: (optionId) async {
                final ok = await runWithFeedback(context, () => service.vote(poll.id, optionId), success: 'Voto registrado');
                if (ok && mounted) setState(() => _version++);
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
