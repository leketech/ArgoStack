import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 400 },    // Ramp up
    { duration: '3h56m', target: 400 }, // Stay at load for ~4 hours
    { duration: '2m', target: 0 },      // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://sample-app.production.svc.cluster.local';

export default function () {
  const response = http.get(`${BASE_URL}/api/users`);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  sleep(1);
}