import 'oauth2_provider.dart';
import 'package:oauth2restclient/src/provider/provider_enum.dart';

class Google extends OAuth2ProviderF {
  Google({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
         name: OAuth2ProviderE.google.name,
         authEndpoint: "https://accounts.google.com/o/oauth2/auth",
         tokenEndpoint: "https://oauth2.googleapis.com/token",
         getUserInfoEndpoint: "https://www.googleapis.com/oauth2/v2/userinfo",
       );
}
