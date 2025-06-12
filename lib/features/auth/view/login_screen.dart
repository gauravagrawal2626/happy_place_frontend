import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:linkedin_login/linkedin_login.dart';
import '../../../utils/linkedin_auth_helper.dart';
import '../bloc/linkedin_auth_bloc.dart';
import '../bloc/linkedin_auth_event.dart';
import '../bloc/linkedin_auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: BlocListener<LinkedInAuthBloc, LinkedInAuthState>(
        listener: (context, state) {
          if (state is LinkedInAuthSuccess) {
            context.go('/home');
          }
        },
        child: BlocBuilder<LinkedInAuthBloc, LinkedInAuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state is LinkedInAuthFailure)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          state.error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (state is LinkedInAuthLoading)
                      const CircularProgressIndicator()
                    else
                      LinkedInButtonStandardWidget(
                        onTap: () {
                          final bloc = context.read<LinkedInAuthBloc>();
                          bloc.add(LinkedInLoginRequested());

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: bloc,
                                child: LinkedInUserWidget(
                                  appBar: AppBar(
                                    title: const Text('LinkedIn Login'),
                                  ),
                                  destroySession: true,
                                  redirectUrl: linkedInRedirectUri,
                                  clientId: linkedInClientId,
                                  clientSecret: linkedInClientSecret,
                                  onGetUserProfile: (UserSucceededAction userSucceededAction) {
                                    bloc.handleLoginSuccess(userSucceededAction);
                                    Navigator.pop(context);
                                  },
                                  onError: (UserFailedAction error) {
                                    bloc.handleLoginError(error);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

