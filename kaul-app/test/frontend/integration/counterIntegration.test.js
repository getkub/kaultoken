import { render, screen, fireEvent } from '@testing-library/react';
import App from '../../../frontend/src/App';
import axios from 'axios';

jest.mock('axios');

describe('Counter Integration', () => {
  it('increments counter across app', async () => {
    axios.post.mockResolvedValue({ data: { count: 1 } });
    render(<App />);
    const button = screen.getByText(/Increment/i);
    fireEvent.click(button);
    expect(await screen.findByText('Counter: 1')).toBeInTheDocument();
  });
});
