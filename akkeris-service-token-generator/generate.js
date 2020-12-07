const assert = require('assert');
const { create_temp_jwt_token } = require('./lib');

assert.ok(process.env.JWT_PRIVATE_KEY, 'The private key environment variable JWT_PRIVATE_KEY was not found.');
assert.ok(process.env.AKKERIS_API, 'The environment variable AKKERIS_API was not found');

// How long the token should be valid for (in seconds).
// Default is 24 hours
const ttl = Number.isInteger(Number.parseInt(process.env.TOKEN_TTL, 10))
  ? Number.parseInt(process.env.TOKEN_TTL, 10) : 60 * 60 * 24;

// Service name of the token requestor
const servicename = process.env.SERVICE_NAME || 'serviceaccount';

// Endpoint of the Akkeris API
const apiEndpoint = process.env.AKKERIS_API;

create_temp_jwt_token(process.env.JWT_PRIVATE_KEY, servicename, apiEndpoint, apiEndpoint, ttl, false, {})
  .then(console.log)
  .catch(console.error);