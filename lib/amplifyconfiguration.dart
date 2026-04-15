// ─────────────────────────────────────────────────────────────────────────────
// amplifyconfiguration.dart
//
// Amplify Flutter 2.x standard format.
// Key rule: OAuth MUST be nested inside Auth.Default (not top-level).
//
// Values from your Cognito setup:
//   - PoolId      : us-west-1_GphwMLAlK
//   - AppClientId : 3tc8nd09sm97du8rd3qlmen7s1
//   - WebDomain   : us-west-1gphwmlalk.auth.us-west-1.amazoncognito.com
// ─────────────────────────────────────────────────────────────────────────────

const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/2.0",
                "Version": "1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-west-1_GphwMLAlK",
                        "AppClientId": "3tc8nd09sm97du8rd3qlmen7s1",
                        "Region": "us-west-1"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "OAuth": {
                            "WebDomain": "us-west-1gphwmlalk.auth.us-west-1.amazoncognito.com",
                            "AppClientId": "3tc8nd09sm97du8rd3qlmen7s1",
                            "SignInRedirectURI": "blrbrebam://callback",
                            "SignOutRedirectURI": "blrbrebam://signout",
                            "Scopes": ["email", "openid"]
                        }
                    }
                }
            }
        }
    }
}''';
