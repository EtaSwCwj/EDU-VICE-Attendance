const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "evattendance": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://aiat7vjfzngx5cyqckc3d5r4dy.appsync-api.ap-northeast-2.amazonaws.com/graphql",
                    "region": "ap-northeast-2",
                    "authorizationType": "AMAZON_COGNITO_USER_POOLS",
                    "apiKey": "da2-jrxsa76kgzhsfberepd77gznie"
                }
            }
        }
    },
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "ap-northeast-2:fb8e97c1-a7f5-4b76-b18d-1e12aa4e973e",
                            "Region": "ap-northeast-2"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "ap-northeast-2_SExWRqKCB",
                        "AppClientId": "2b0nlu3n5o21v9m0oshfg4jsoc",
                        "Region": "ap-northeast-2"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "socialProviders": [],
                        "usernameAttributes": [],
                        "signupAttributes": [
                            "EMAIL"
                        ],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "mfaConfiguration": "OFF",
                        "mfaTypes": [
                            "SMS"
                        ],
                        "verificationMechanisms": [
                            "EMAIL"
                        ]
                    }
                },
                "AppSync": {
                    "Default": {
                        "ApiUrl": "https://aiat7vjfzngx5cyqckc3d5r4dy.appsync-api.ap-northeast-2.amazonaws.com/graphql",
                        "Region": "ap-northeast-2",
                        "AuthMode": "AMAZON_COGNITO_USER_POOLS",
                        "ClientDatabasePrefix": "evattendance_AMAZON_COGNITO_USER_POOLS"
                    },
                    "evattendance_API_KEY": {
                        "ApiUrl": "https://aiat7vjfzngx5cyqckc3d5r4dy.appsync-api.ap-northeast-2.amazonaws.com/graphql",
                        "Region": "ap-northeast-2",
                        "AuthMode": "API_KEY",
                        "ApiKey": "da2-jrxsa76kgzhsfberepd77gznie",
                        "ClientDatabasePrefix": "evattendance_API_KEY"
                    }
                }
            }
        }
    }
}''';
