import 'package:linkedin_login/linkedin_login.dart';

import '../core/config/env_config.dart';

// LinkedIn OAuth: read from .env (LINKEDIN_CLIENT_ID, LINKEDIN_CLIENT_SECRET, LINKEDIN_REDIRECT_URI).
// Configure at https://www.linkedin.com/developers/apps

String get linkedInClientId => EnvConfig.linkedInClientId;
String get linkedInClientSecret => EnvConfig.linkedInClientSecret;
String get linkedInRedirectUri => EnvConfig.linkedInRedirectUri;