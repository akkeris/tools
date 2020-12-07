const assert = require('assert');
const jose = require('node-jose');

function sign_to_token(signature) {
  return signature.signatures[0].protected + 
    "." + signature.payload + 
    "." + signature.signatures[0].signature;
}

async function jwks_sign(pem, data) {
  assert.ok(pem, 'The private key JWT_PRIVATE_KEY was not found.');
  if(Buffer.isBuffer(pem)) {
    pem = pem.toString('utf8');
  }
  pem = pem.trim();
  if(typeof data !== 'string') {
    data = JSON.stringify(data);
  }
  return await jose.JWS.createSign({ "alg": "RS256"}, await jose.JWK.asKey(pem, 'pem')).update(data).final()
}

async function jwks_verify(pem, token, intended_issuer, intended_audience) {

  const cert = await jose.JWK.asKey(pem, 'pem');
  const result = await jose.JWS.createVerify(cert).verify(token);

  const payload = JSON.parse(result.payload.toString('utf8'));

  // check standard JWT token parameters
  assert.ok(
    (payload.iss && intended_issuer && payload.iss === intended_issuer) || !intended_issuer || !payload.iss,
    'Unauthorized: issuer is invalid',
  );

  assert.ok(payload.exp && payload.exp > Math.floor((new Date()).getTime() / 1000), 'Unauthorized: token is expired, or has no "exp" field.');

  assert.ok(
    (payload.aud && intended_audience && payload.aud === intended_audience) || !intended_audience || !payload.aud,
    'Unauthorized: audience is invalid',
  );

  assert.ok(
    (payload.nbf && payload.nbf < Math.floor((new Date()).getTime()) / 1000) || !payload.nbf,
    'Unauthorized: token cannot be used yet, now < "nbf" field.',
  );

  return payload;
}
  
/**
 * Create a JWT token that expires after a specified number of seconds
 * @param {string} pem SSL private key
 * @param {string} username Who made the request https://tools.ietf.org/html/rfc7519#section-4.1.2
 * @param {string} audience Who this token is intended for (https://tools.ietf.org/html/rfc7519#section-4.1.3)
 * @param {string} issuer Who issued this token (https://tools.ietf.org/html/rfc7519#section-4.1.1)
 * @param {number} ttl Time (in seconds) that this token should be valid for
 * @param {boolean} elevated_access Does the user have elevated access?
 * @param {object} metadata Additional data to add to the claim
 */
async function create_temp_jwt_token(pem, username, audience, issuer, ttl, elevated_access, metadata = {}) {
  if (!pem || pem === '' || pem.length === 0 || (typeof pem === 'string' && pem.trim() === '')) {
    return null;
  }
  const payload = {
    ...metadata,
    sub: username,
    ele: elevated_access,
    aud: audience,
    iss: issuer,
    exp: Math.floor((new Date()).getTime() / 1000) + ttl + 60, // expiration date (https://tools.ietf.org/html/rfc7519#section-4.1.4) - allow 1 minute of drift.
    nbf: Math.floor((new Date()).getTime() / 1000) - 60, // token is not valid before (https://tools.ietf.org/html/rfc7519#section-4.1.5) - allow 1 minute of drift.
    jti: Math.round(Math.random() * (Number.MAX_VALUE - 1)), // Random unique identifier for this token. (https://tools.ietf.org/html/rfc7519#section-4.1.7)
  };
  return sign_to_token(await jwks_sign(pem, payload));
}

module.exports = {
  create_temp_jwt_token,
  jwks_verify
}
