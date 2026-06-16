import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/results_repository.dart';
import '../domain/exam_result.dart';

part 'results_state.dart';

class ResultsCubit extends Cubit<ResultsState> {
  ResultsCubit(this._repo) : super(const ResultsInitial());
  final ResultsRepository _repo;

  Future<void> loadFor(int studentId) async {
    emit(const ResultsLoading());
    try {
      final results = await _repo.fetchFor(studentId);
      emit(ResultsLoaded(results));
    } catch (e) {
      emit(ResultsError(e.toString()));
    }
  }
}
