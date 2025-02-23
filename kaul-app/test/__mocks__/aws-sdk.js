const AWS = {
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      update: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({ Attributes: { count: 0 } }),
      }),
    })),
  },
};
module.exports = AWS;
