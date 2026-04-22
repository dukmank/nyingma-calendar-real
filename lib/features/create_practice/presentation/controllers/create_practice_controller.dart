import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatePracticeState {
  final String title;
  final String content;
  final bool isLoading;
  final bool isSaved;

  const CreatePracticeState({
    this.title = '',
    this.content = '',
    this.isLoading = false,
    this.isSaved = false,
  });

  CreatePracticeState copyWith({String? title, String? content, bool? isLoading, bool? isSaved}) =>
      CreatePracticeState(
        title: title ?? this.title,
        content: content ?? this.content,
        isLoading: isLoading ?? this.isLoading,
        isSaved: isSaved ?? this.isSaved,
      );
}

class CreatePracticeController extends StateNotifier<CreatePracticeState> {
  CreatePracticeController() : super(const CreatePracticeState());

  void setTitle(String v) => state = state.copyWith(title: v);
  void setContent(String v) => state = state.copyWith(content: v);

  Future<void> save() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false, isSaved: true);
  }
}

final createPracticeControllerProvider =
    StateNotifierProvider.autoDispose<CreatePracticeController, CreatePracticeState>(
  (_) => CreatePracticeController(),
);
