// Test Supabase signUp with different email formats to diagnose the issue
const SUPABASE_URL = 'https://pzugizdkhvppqadiaxgq.supabase.co';
const ANON_KEY = 'sb_publishable_opvEIIVFPbsIUgAAbefc4Q_fzxbwsY7';

async function testSignUp(email, password) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({
      email,
      password,
      data: { username: 'testuser' },
    }),
  });
  const body = await res.json();
  console.log(`\n--- Test: "${email}" ---`);
  console.log(`Status: ${res.status}`);
  console.log(`Response:`, JSON.stringify(body, null, 2));
  return { status: res.status, body };
}

async function main() {
  console.log('Testing Supabase Auth signUp with different email formats...\n');

  // Test 1: Real-looking email (control)
  await testSignUp('testuser12345@example.com', 'password123');

  // Test 2: Our current format
  await testSignUp('a1b2c3d4e5f6a7b8c9d0@darktrade.app', 'password123');

  // Test 3: Simple ASCII username
  await testSignUp('simpleuser@darktrade.app', 'password123');

  // Test 4: Just to see what the current hash format produces
  const crypto = await import('crypto');
  const hash = crypto.createHash('sha256').update('darktrade:testuser').digest('hex').substring(0, 20);
  console.log(`\nComputed hash for 'testuser': ${hash}`);
  await testSignUp(`${hash}@darktrade.app`, 'password123');
}

main().catch(console.error);
