const assert = require('assert');
const { create_temp_jwt_token } = require('./lib');

assert.ok(process.env.JWT_PRIVATE_KEY, 'The private key environment variable JWT_PRIVATE_KEY was not found.');
assert.ok(process.env.AKKERIS_API, 'The environment variable AKKERIS_API was not found');

// How long the token should be valid for (in seconds).
// Default is 24 hours
const ttl = Number.isInteger(Number.parseInt(process.env.TOKEN_TTL, 10))
  ? Number.parseInt(process.env.TOKEN_TTL, 10) : 60 * 60 * 24;

// Username of the token requestor
const username = process.env.USERNAME || 'serviceaccount';

// Endpoint of the Akkeris API
const apiEndpoint = process.env.AKKERIS_API;

create_temp_jwt_token(process.env.JWT_PRIVATE_KEY, username, apiEndpoint, apiEndpoint, ttl, false, {})
  .then(console.log)
  .catch(console.error);