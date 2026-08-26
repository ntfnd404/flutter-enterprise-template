part of 'activity_bloc.dart';

sealed class _ActivityEvent {
  const _ActivityEvent();
}

final class _DraftCreationObserved extends _ActivityEvent {
  const _DraftCreationObserved(this.sequence);

  final int sequence;
}
