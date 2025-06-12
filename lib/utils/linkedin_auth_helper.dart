import 'package:linkedin_login/linkedin_login.dart';

// LinkedIn OAuth Configuration
// Make sure these values match your LinkedIn App settings at https://www.linkedin.com/developers/apps

// Your LinkedIn App's Client ID
const String linkedInClientId = '86u2rorm0akb59';

// Your LinkedIn App's Client Secret
const String linkedInClientSecret = 'REDACTED_USE_ENV';

// The redirect URI must be:
// 1. Added to your LinkedIn App's OAuth 2.0 settings
// 2. Be a valid URL that your app can handle
const String linkedInRedirectUri = 'https://httpstat.us/200';