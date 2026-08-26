import 'package:template/core/event_bus/app_event.dart';

/// Best-effort notice that one monitored draft-creation operation committed.
///
/// [operationSequence] correlates only one presentation flow. It is not an
/// Order identity, authoritative state, delivery acknowledgement, or durable
/// integration-event sequence. A subscriber may miss this event.
final class OrderDraftCreatedAppEvent extends AppEvent {
  /// Creates a live presentation notification.
  const OrderDraftCreatedAppEvent({required this.operationSequence});

  /// Positive, screen-lifetime correlation sequence.
  final int operationSequence;
}
