# Akkeris Service Token Generator

Utility to generate Akkeris service tokens.

## Instructions

Set your `kubectl` context to the cluster that your Akkeris installation is running in.

Then, run `npm run generate-token [SERVICE_NAME] <TTL>` to generate a new service token.

- `SERVICE_NAME` should be set to the name of the service requesting the service token
- `TTL` is optional, and represents the time that the token should be valid for (in seconds). 
  - Default is 86400 (24 hours in seconds = 60 * 60 * 24).

### Example

```bash
kubectl config use-context mycluster
npm run generate-token myservice
```

## Token Verification

To verify the generated token, you can do the following:

`npm run verify-token [TOKEN]`

e.g.

`npm run verify-token eyJhbGc...`

## TODO

Add option for generating tokens with elevated access