import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 100 },  // Fast ramp-up to high load
    { duration: '1m', target: 100 },   // Stay at high load
    { duration: '10s', target: 1400 }, // Spike to very high load
    { duration: '3m', target: 1400 },  // Stay at spike
    { duration: '10s', target: 100 },  // Quick scale down
    { duration: '3m', target: 100 },   // Recovery stage
    { duration: '10s', target: 0 },    // Ramp down
  ],
};

const BASE_URL = __ENV.BASE_URL || 'http://sample-app.production.svc.cluster.local';

export default function () {
  http.get(`${BASE_URL}/api/users`);
  sleep(1);
}