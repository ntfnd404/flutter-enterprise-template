part of 'startup_failure_bloc.dart';

/// Base type for future startup recovery intents.
///
/// No concrete event is added until a safe pre-DI recovery operation exists.
sealed class StartupFailureEvent {
  const StartupFailureEvent();
}
