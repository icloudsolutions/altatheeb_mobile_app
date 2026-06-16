part of 'attendance_cubit.dart';

sealed class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceLoaded extends AttendanceState {
  const AttendanceLoaded(this.summary);
  final AttendanceSummary summary;
  @override
  List<Object?> get props => [summary];
}

class AttendanceError extends AttendanceState {
  const AttendanceError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
