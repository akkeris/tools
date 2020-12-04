const assert = require('assert');
const { jwks_verify } = require('./lib');
const jose = require('node-jose');

assert.ok(process.env.JWT_RS256_PUBLIC_CERT, 'The environment variable JWT_RS256_PUBLIC_CERT was not found.');
assert.ok(process.env.AKKERIS_API, 'The environment variable AKKERIS_API was not found');
assert.ok(process.env.TOKEN, 'The environment variable TOKEN was not found');

const [ claims, signature ] = process.env.TOKEN.split('.');
const decodedClaims = jose.util.base64url.decode(claims).toString('utf8');

console.log(signature)

jwks_verify(
  process.env.JWT_RS256_PUBLIC_CERT,
  process.env.AKKERIS_API,
  process.env.AKKERIS_API,
  decodedClaims,
  signature
).then(result => {
  console.log(result);
}).catch(err => {
  console.log(err);
});
