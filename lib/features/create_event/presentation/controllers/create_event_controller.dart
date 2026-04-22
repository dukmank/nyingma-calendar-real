import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEventState {
  final String title;
  final String content;
  final bool isLoading;
  final bool isSaved;

  const CreateEventState({
    this.title = '',
    this.content = '',
    this.isLoading = false,
    this.isSaved = false,
  });

  CreateEventState copyWith({String? title, String? content, bool? isLoading, bool? isSaved}) =>
      CreateEventState(
        title: title ?? this.title,
        content: content ?? this.content,
        isLoading: isLoading ?? this.isLoading,
        isSaved: isSaved ?? this.isSaved,
      );
}

class CreateEventController extends StateNotifier<CreateEventState> {
  CreateEventController() : super(const CreateEventState());

  void setTitle(String v) => state = state.copyWith(title: v);
  void setContent(String v) => state = state.copyWith(content: v);

  Future<void> save() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false, isSaved: true);
  }
}

final createEventControllerProvider =
    StateNotifierProvider.autoDispose<CreateEventController, CreateEventState>(
  (_) => CreateEventController(),
);
