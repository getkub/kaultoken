import { render, screen, fireEvent } from '@testing-library/react';
import CounterComponent from '../../../frontend/src/modules/counter/CounterComponent';
import axios from 'axios';

jest.mock('axios');

describe('CounterComponent', () => {
  beforeEach(() => {
    axios.post.mockResolvedValue({ data: { count: 1 } });
  });

  it('increments count on button click', async () => {
    render(<CounterComponent />);
    const button = screen.getByText(/Increment/i);
    fireEvent.click(button);
    expect(await screen.findByText('Counter: 1')).toBeInTheDocument();
  });

  it('displays initial count of 0', () => {
    render(<CounterComponent />);
    expect(screen.getByText('Counter: 0')).toBeInTheDocument();
  });
});
