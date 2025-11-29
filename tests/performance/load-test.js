/**
 * Blood Pressure Calculator - k6 Performance Test
 * 
 * This test simulates realistic user load on the BP Calculator application
 * to validate performance under various concurrency levels.
 * 
 * Test Stages:
 * 1. Ramp-up: 0 → 10 users over 30 seconds
 * 2. Sustained: 10 users for 1 minute
 * 3. Peak: 10 → 50 users over 30 seconds
 * 4. Peak sustained: 50 users for 2 minutes
 * 5. Ramp-down: 50 → 0 users over 30 seconds
 * 
 * Usage:
 *   k6 run load-test.js
 *   k6 run --env BASE_URL=http://your-staging-url load-test.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const pageLoadTime = new Trend('page_load_time');
const calculationTime = new Trend('calculation_time');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp-up to 10 users
    { duration: '1m', target: 10 },    // Stay at 10 users
    { duration: '30s', target: 50 },   // Ramp-up to 50 users (peak)
    { duration: '2m', target: 50 },    // Stay at 50 users
    { duration: '30s', target: 0 },    // Ramp-down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // 95% < 500ms, 99% < 1s
    http_req_failed: ['rate<0.01'],                   // <1% errors
    errors: ['rate<0.01'],                            // <1% custom errors
    page_load_time: ['p(95)<1000'],                   // 95% page loads < 1s
    calculation_time: ['p(95)<200'],                  // 95% calculations < 200ms
  },
};

// Base URL - can be overridden via environment variable
const BASE_URL = __ENV.BASE_URL || 'http://bp-calculator-staging.eba-gb3zir6t.eu-west-1.elasticbeanstalk.com';

// Test data - realistic BP values
const testCases = [
  { systolic: 85, diastolic: 55, expected: 'Low' },
  { systolic: 110, diastolic: 70, expected: 'Ideal' },
  { systolic: 130, diastolic: 85, expected: 'Pre-High' },
  { systolic: 150, diastolic: 95, expected: 'High' },
  { systolic: 120, diastolic: 80, expected: 'Ideal' },
  { systolic: 140, diastolic: 90, expected: 'Pre-High' },
];

export default function () {
  // Test 1: Load homepage
  const homePageStart = new Date();
  let res = http.get(BASE_URL);
  const homePageDuration = new Date() - homePageStart;
  
  const homePageCheck = check(res, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage loads in time': (r) => r.timings.duration < 1000,
    'homepage contains title': (r) => r.body.includes('Blood Pressure'),
  });
  
  pageLoadTime.add(homePageDuration);
  errorRate.add(!homePageCheck);
  
  sleep(1); // Think time - user reads the page
  
  // Test 2: Calculate blood pressure
  const testCase = testCases[Math.floor(Math.random() * testCases.length)];
  
  const calcStart = new Date();
  res = http.post(BASE_URL, {
    'BP.Systolic': testCase.systolic.toString(),
    'BP.Diastolic': testCase.diastolic.toString(),
  });
  const calcDuration = new Date() - calcStart;
  
  const calcCheck = check(res, {
    'calculation status is 200': (r) => r.status === 200,
    'calculation returns result': (r) => r.body.includes('Category:') || r.body.includes(testCase.expected),
    'calculation completes quickly': (r) => r.timings.duration < 500,
  });
  
  calculationTime.add(calcDuration);
  errorRate.add(!calcCheck);
  
  sleep(2); // Think time - user reviews result
  
  // Test 3: Invalid input handling
  res = http.post(BASE_URL, {
    'BP.Systolic': '999',
    'BP.Diastolic': '50',
  });
  
  check(res, {
    'validation status is 200': (r) => r.status === 200,
    'validation shows error': (r) => r.body.includes('validation') || r.body.includes('invalid') || r.body.includes('error'),
  });
  
  sleep(1);
}

// Setup function - runs once before tests
export function setup() {
  console.log(`Starting load test against: ${BASE_URL}`);
  
  // Verify application is reachable
  const res = http.get(BASE_URL);
  if (res.status !== 200) {
    throw new Error(`Application not reachable. Status: ${res.status}`);
  }
  
  console.log('Application is reachable. Starting load test...');
  return { baseUrl: BASE_URL };
}

// Teardown function - runs once after tests
export function teardown(data) {
  console.log('Load test completed.');
}

// Handle summary
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'performance-report.json': JSON.stringify(data),
  };
}

function textSummary(data, options = {}) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;
  
  let summary = '\n' + indent + '=== Performance Test Summary ===\n\n';
  
  // HTTP metrics
  summary += indent + 'HTTP Requests:\n';
  summary += indent + `  Total: ${data.metrics.http_reqs.values.count}\n`;
  summary += indent + `  Failed: ${data.metrics.http_req_failed.values.rate * 100}%\n`;
  summary += indent + `  Duration (avg): ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms\n`;
  summary += indent + `  Duration (p95): ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  summary += indent + `  Duration (p99): ${data.metrics.http_req_duration.values['p(99)'].toFixed(2)}ms\n\n`;
  
  // Custom metrics
  summary += indent + 'Custom Metrics:\n';
  summary += indent + `  Error Rate: ${data.metrics.errors.values.rate * 100}%\n`;
  summary += indent + `  Page Load (avg): ${data.metrics.page_load_time.values.avg.toFixed(2)}ms\n`;
  summary += indent + `  Page Load (p95): ${data.metrics.page_load_time.values['p(95)'].toFixed(2)}ms\n`;
  summary += indent + `  Calculation (avg): ${data.metrics.calculation_time.values.avg.toFixed(2)}ms\n`;
  summary += indent + `  Calculation (p95): ${data.metrics.calculation_time.values['p(95)'].toFixed(2)}ms\n\n`;
  
  // Thresholds
  summary += indent + 'Thresholds:\n';
  const thresholds = data.root_group.checks;
  for (const [name, value] of Object.entries(thresholds || {})) {
    const status = value.fails === 0 ? '✓ PASS' : '✗ FAIL';
    summary += indent + `  ${status}: ${name}\n`;
  }
  
  return summary;
}
