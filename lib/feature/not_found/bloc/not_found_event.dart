part of 'not_found_bloc.dart';

/// Base type for future recovery intents accepted by `NotFoundBloc`.
///
/// No concrete event is added until the recovery screen has real behavior.
sealed class NotFoundEvent {
  const NotFoundEvent();
}
