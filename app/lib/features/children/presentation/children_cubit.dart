import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/children_repository.dart';
import '../domain/child.dart';

sealed class ChildrenState {
  const ChildrenState();
}

class ChildrenInitial extends ChildrenState {
  const ChildrenInitial();
}

class ChildrenLoading extends ChildrenState {
  const ChildrenLoading();
}

class ChildrenLoaded extends ChildrenState {
  const ChildrenLoaded(this.children, {this.selected});
  final List<Child> children;
  final Child? selected;
}

class ChildrenError extends ChildrenState {
  const ChildrenError(this.message);
  final String message;
}

class ChildrenCubit extends Cubit<ChildrenState> {
  ChildrenCubit(this._repo) : super(const ChildrenInitial());

  final ChildrenRepository _repo;

  Future<void> load() async {
    if (!isClosed) emit(const ChildrenLoading());
    try {
      final list = await _repo.list();
      if (!isClosed) {
        emit(ChildrenLoaded(list, selected: list.isNotEmpty ? list.first : null));
      }
    } catch (e) {
      if (!isClosed) emit(ChildrenError(e.toString()));
    }
  }

  void select(Child child) {
    if (isClosed) return;
    final s = state;
    if (s is ChildrenLoaded) {
      emit(ChildrenLoaded(s.children, selected: child));
    }
  }
}
