const { handler } = require('../../serverless/counter/increment');

describe('Counter API Integration', () => {
  it('increments counter via simulated API call', async () => {
    const event = {
      body: JSON.stringify({ counterId: 'demo' }),
      httpMethod: 'POST',
      path: '/api/v1/counter/increment',
    };
    const result = await handler(event);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.success).toBe(true);
    expect(body.count).toBeGreaterThan(0);
  });
});
