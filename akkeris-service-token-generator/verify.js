const { execSync } = require('child_process');
const { jwks_verify } = require('./lib');

const usage = () => {
  console.log('USAGE: verify-token [TOKEN]')
  console.log('  - TOKEN: Token to verify (required)')
  console.log('')
  console.log('e.g. npm run verify-token eyJhbGc...')
  process.exit(1);
}

const fetchString = (key) => `kubectl get cm -n akkeris-system controller-api -o jsonpath="{.data.${key}}"`;

const args = process.argv.slice(2);

// Validate arguments
if (args.length < 1) {
  usage();
}

const token = args[0];

let apiURL;
let jwtPrivateKey;

// Fetch private key and issuer/audience from Kubernetes
try {
  apiURL = execSync(fetchString("AKKERIS_API_URL")).toString();
  jwtPrivateKey = execSync(fetchString("JWT_RS256_PRIVATE_KEY")).toString();
} catch (err) {
  console.log('Error fetching controller-api configuration from Kubernetes:')
  if (err.stderr) {
    console.log(err.stderr.toString()) 
  } else {
    console.log(err)
  }
  return;
}

jwks_verify(jwtPrivateKey, token, apiURL, apiURL)
  .then(console.log)
  .catch(console.error);