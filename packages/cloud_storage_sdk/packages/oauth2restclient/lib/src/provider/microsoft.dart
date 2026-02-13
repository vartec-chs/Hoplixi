import 'oauth2_provider.dart';
import 'package:oauth2restclient/src/provider/provider_enum.dart';

class Microsoft extends OAuth2ProviderF {
  Microsoft({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
         name: OAuth2ProviderE.microsoft.name,
         authEndpoint:
             "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
         tokenEndpoint:
             "https://login.microsoftonline.com/common/oauth2/v2.0/token",
         getUserInfoEndpoint: "https://graph.microsoft.com/v1.0/me",
       );
}
