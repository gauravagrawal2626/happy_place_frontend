import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linkedin_login/linkedin_login.dart';
import '../../../utils/linkedin_auth_helper.dart';
import '../model/linkedin_user_model.dart';
import 'linkedin_auth_event.dart';
import 'linkedin_auth_state.dart';

class LinkedInAuthBloc extends Bloc<LinkedInAuthEvent, LinkedInAuthState> {
  LinkedInAuthBloc() : super(LinkedInAuthInitial()) {
    on<LinkedInLoginRequested>(_onLinkedInLoginRequested);
    on<LinkedInLogoutRequested>(_onLinkedInLogoutRequested);
  }

  Future<void> _onLinkedInLoginRequested(
    LinkedInLoginRequested event,
    Emitter<LinkedInAuthState> emit,
  ) async {
    emit(LinkedInAuthLoading());
  }

  Future<void> _onLinkedInLogoutRequested(
    LinkedInLogoutRequested event,
    Emitter<LinkedInAuthState> emit,
  ) async {
    emit(LinkedInAuthInitial());
  }

  void handleLoginSuccess(UserSucceededAction userSucceededAction) {
    final user = AppLinkedInUser.fromLinkedInUser(userSucceededAction);
    emit(LinkedInAuthSuccess(user: user));
  }

  void handleLoginError(UserFailedAction error) {
    emit(LinkedInAuthFailure(error: error.toString()));
  }
} 