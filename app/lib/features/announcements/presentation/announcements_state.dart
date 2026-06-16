part of 'announcements_cubit.dart';

sealed class AnnouncementsState extends Equatable {
  const AnnouncementsState();
  @override
  List<Object?> get props => [];
}

class AnnouncementsInitial extends AnnouncementsState {
  const AnnouncementsInitial();
}

class AnnouncementsLoading extends AnnouncementsState {
  const AnnouncementsLoading();
}

class AnnouncementsLoaded extends AnnouncementsState {
  const AnnouncementsLoaded(this.announcements);
  final List<Announcement> announcements;
  @override
  List<Object?> get props => [announcements];
}

class AnnouncementsError extends AnnouncementsState {
  const AnnouncementsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
