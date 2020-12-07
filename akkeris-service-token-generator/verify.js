const assert = require('assert');
const { jwks_verify } = require('./lib');
const jose = require('node-jose');

assert.ok(process.env.JWT_PRIVATE_KEY, 'The environment variable JWT_PRIVATE_KEY was not found.');
assert.ok(process.env.AKKERIS_API, 'The environment variable AKKERIS_API was not found');
assert.ok(process.env.TOKEN, 'The environment variable TOKEN was not found');

jwks_verify(
  process.env.JWT_PRIVATE_KEY,
  process.env.TOKEN,
  process.env.AKKERIS_API,
  process.env.AKKERIS_API,
)
  .then(console.log)
  .catch(console.error);