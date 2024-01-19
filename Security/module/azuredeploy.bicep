module secret '../secrets/main.bicep' = {
  name: 'keyvaultsecret'
  params: {
    secretContentType: 'text/plain'
    secretExp: 1737158400
    secretNbf: 1705622400
    secretName: 'passphraseKey'
    secretValue: 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAEUCn0P068Yu9DrM2v4wwNhRcho3rOzrQ4Y5gYOy4+RPofg75KyQoYDKHiwWqkO+2xzoRPAZIhCKXEQlLDa/q0ZFABO0KzYet/Y7vE/zm0tCQpQxJiRP1IrGqtSrz1X3bVo9BJeAGonoPAdYujZylBwUBsw/GA5eSO3GwIUFgYxQaMQDA== zadmin@mstunnel.intheclouds365.com'
  }
}
output name string = secret.name
