const { handler } = require('../../serverless/counter/increment');
const AWS = require('aws-sdk');

jest.mock('aws-sdk', () => {
  const mDocumentClient = {
    update: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({ Attributes: { count: 1 } }),
    }),
  };
  return { DynamoDB: { DocumentClient: jest.fn(() => mDocumentClient) } };
});

describe('counterIncrement', () => {
  it('increments counter and returns new count', async () => {
    const event = { body: JSON.stringify({ counterId: 'demo' }) };
    const result = await handler(event);

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body)).toEqual({ success: true, count: 1 });
  });

  it('handles errors gracefully', async () => {
    AWS.DynamoDB.DocumentClient().update.mockReturnValue({
      promise: jest.fn().mockRejectedValue(new Error('DynamoDB error')),
    });
    const event = { body: JSON.stringify({ counterId: 'demo' }) };
    const result = await handler(event);

    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).error).toBe('DynamoDB error');
  });
});
