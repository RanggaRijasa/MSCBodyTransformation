const apiUrl = process.env.API_URL;

if (!apiUrl) {
  throw new Error('API_URL lokal wajib tersedia.');
}

const parsedUrl = new URL(apiUrl);
if (!['127.0.0.1', 'localhost'].includes(parsedUrl.hostname)) {
  throw new Error('Edge Function verification ditolak untuk target non-lokal.');
}

const cases = [
  { name: 'delete-account', method: 'POST', status: 401 },
  { name: 'cleanup-orphan-question-photos', method: 'POST', status: 401 },
  { name: 'commerce', method: 'POST', status: 401 },
  { name: 'commerce-apple-notifications', method: 'POST', status: 422 },
  { name: 'apple-identity-lifecycle', method: 'POST', status: 500, code: 'server_configuration_missing' },
  { name: 'apple-account-events', method: 'POST', status: 500, code: 'apple_identity_operation_failed' },
  { name: 'apple-identity-reconciliation', method: 'POST', status: 500, code: 'server_configuration_missing' },
  { name: 'apple-commerce-reconciliation', method: 'POST', status: 500, code: 'commerce_environment_missing' },
  { name: 'legal/privacy', method: 'GET', status: 200 },
  { name: 'cleanup-orphan-payment-evidence', method: 'POST', status: 401 },
  { name: 'process-food-insight', method: 'POST', status: 401 },
  { name: 'process-provisional-cancellations', method: 'POST', status: 401 },
  { name: 'public-coach-media/00000000-0000-0000-0000-000000000000', method: 'GET', status: 404 },
];

const results = [];
for (const testCase of cases) {
  const response = await fetch(`${apiUrl}/functions/v1/${testCase.name}`, {
    method: testCase.method,
  });
  if (response.status !== testCase.status) {
    throw new Error(`${testCase.name}: expected HTTP ${testCase.status}, received ${response.status}`);
  }
  if (testCase.code) {
    const body = await response.json().catch(() => null);
    if (body?.code !== testCase.code) {
      throw new Error(`${testCase.name}: expected safe error code ${testCase.code}`);
    }
  } else {
    await response.arrayBuffer();
  }
  results.push({ function: testCase.name.split('/')[0], status: response.status });
}

console.log(JSON.stringify({ target: 'local', results }, null, 2));
