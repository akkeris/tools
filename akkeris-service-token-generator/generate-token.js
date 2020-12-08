const { execSync } = require('child_process');
const { create_temp_jwt_token } = require('./lib');

const usage = () => {
  console.log('USAGE: generate-token [SERVICE_NAME] <TTL>')
  console.log('  - SERVICE_NAME: Name of service that is requesting the token (required)')
  console.log('  - TTL: Time (in seconds) that the tokens should be valid for (optional, default 24 hours)')
  console.log('')
  console.log('e.g. npm run generate-token myservice 86400')
  process.exit(1);
}

const fetchString = (key) => `kubectl get cm -n akkeris-system controller-api -o jsonpath="{.data.${key}}"`;

const DEFAULT_TTL=60 * 60 * 24;

const args = process.argv.slice(2);

// Validate arguments
if (args.length < 1) {
  usage();
}

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

// Service name (token requestor)
const servicename = args[0];

let ttl = DEFAULT_TTL;
if (args[1]) {
  if (!Number.isInteger(Number.parseInt(args[1], 10))) {
    console.log(`${args[1]} was not a valid integer. Using default TTL of ${DEFAULT_TTL}`)
  } else {
    ttl = Number.parseInt(args[1], 10);
  }
}

create_temp_jwt_token(jwtPrivateKey, servicename, apiURL, apiURL, ttl, false, {})
  .then(console.log)
  .catch(console.error);
