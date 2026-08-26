part of 'activity_bloc.dart';

sealed class _ActivityEvent {
  const _ActivityEvent();
}

final class _DemoActionObserved extends _ActivityEvent {
  const _DemoActionObserved(this.sequence);

  final int sequence;
}
