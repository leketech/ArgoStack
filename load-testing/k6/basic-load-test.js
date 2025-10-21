import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const requestDuration = new Trend('request_duration');
const requestCount = new Counter('request_count');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://sample-app.production.svc.cluster.local';

export default function () {
  // Test GET /api/users
  let response = http.get(`${BASE_URL}/api/users`, {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'GetUsers' },
  });

  // Check response
  const result = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'body contains users': (r) => r.body.includes('users'),
  });

  // Record metrics
  errorRate.add(!result);
  requestDuration.add(response.timings.duration);
  requestCount.add(1);

  sleep(1);

  // Test GET /api/users/:id
  const userId = Math.floor(Math.random() * 100) + 1;
  response = http.get(`${BASE_URL}/api/users/${userId}`, {
    tags: { name: 'GetUser' },
  });

  check(response, {
    'user fetch status is 200 or 404': (r) => r.status === 200 || r.status === 404,
  });

  sleep(1);

  // Test POST /api/users
  const payload = JSON.stringify({
    name: `User${Math.random().toString(36).substring(7)}`,
    email: `user${Date.now()}@example.com`,
  });

  response = http.post(`${BASE_URL}/api/users`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'CreateUser' },
  });

  check(response, {
    'user creation status is 201': (r) => r.status === 201,
  });

  sleep(1);
}