import axios from 'axios';
import { incrementCounter } from '../../../frontend/src/modules/counter/CounterService';

jest.mock('axios');

describe('CounterService', () => {
  it('calls increment API and returns new count', async () => {
    axios.post.mockResolvedValue({ data: { count: 2 } });
    const result = await incrementCounter('demo');
    expect(axios.post).toHaveBeenCalledWith('http://localhost:3001/api/v1/counter/increment', { counterId: 'demo' });
    expect(result).toBe(2);
  });
});
