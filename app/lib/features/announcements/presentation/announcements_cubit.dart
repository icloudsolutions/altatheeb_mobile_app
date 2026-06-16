import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/announcements_repository.dart';
import '../domain/announcement.dart';

part 'announcements_state.dart';

class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  AnnouncementsCubit(this._repo) : super(const AnnouncementsInitial());
  final AnnouncementsRepository _repo;

  Future<void> load({int? schoolId}) async {
    emit(const AnnouncementsLoading());
    try {
      final items = await _repo.fetch(schoolId: schoolId);
      emit(AnnouncementsLoaded(items));
    } catch (e) {
      emit(AnnouncementsError(e.toString()));
    }
  }
}
