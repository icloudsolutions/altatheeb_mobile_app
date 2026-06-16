part of 'results_cubit.dart';

sealed class ResultsState extends Equatable {
  const ResultsState();
  @override
  List<Object?> get props => [];
}

class ResultsInitial extends ResultsState {
  const ResultsInitial();
}

class ResultsLoading extends ResultsState {
  const ResultsLoading();
}

class ResultsLoaded extends ResultsState {
  const ResultsLoaded(this.results);
  final List<ExamResult> results;
  @override
  List<Object?> get props => [results];
}

class ResultsError extends ResultsState {
  const ResultsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
