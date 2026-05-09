import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invoices_repository.dart';
import '../domain/invoice.dart';

sealed class InvoicesState {
  const InvoicesState();
}

class InvoicesInitial extends InvoicesState {
  const InvoicesInitial();
}

class InvoicesLoading extends InvoicesState {
  const InvoicesLoading();
}

class InvoicesLoaded extends InvoicesState {
  const InvoicesLoaded(this.invoices);
  final List<Invoice> invoices;
}

class InvoicesError extends InvoicesState {
  const InvoicesError(this.message);
  final String message;
}

class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit(this._repo) : super(const InvoicesInitial());
  final InvoicesRepository _repo;

  Future<void> loadFor(int studentId) async {
    emit(const InvoicesLoading());
    try {
      emit(InvoicesLoaded(await _repo.forChild(studentId)));
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }
}
