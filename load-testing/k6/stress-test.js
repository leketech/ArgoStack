import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Below normal load
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },   // Normal load
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },   // Around breaking point
    { duration: '5m', target: 300 },
    { duration: '2m', target: 400 },   // Beyond breaking point
    { duration: '5m', target: 400 },
    { duration: '10m', target: 0 },    // Scale down (recovery)
  ],
  thresholds: {
    http_req_duration: ['p(99)<1500'],
    'http_req_duration{staticAsset:yes}': ['p(99)<1000'],
    http_req_failed: ['rate<0.05'],
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