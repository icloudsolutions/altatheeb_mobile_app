import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/attendance_repository.dart';
import '../domain/attendance_record.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._repo) : super(const AttendanceInitial());
  final AttendanceRepository _repo;

  Future<void> loadFor(int studentId, {String? from, String? to}) async {
    emit(const AttendanceLoading());
    try {
      final summary = await _repo.fetchFor(studentId, from: from, to: to);
      emit(AttendanceLoaded(summary));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }
}
