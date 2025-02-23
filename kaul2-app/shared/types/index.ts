export interface Subject {
  id: string;
  title: string;
  description: string;
  walletAddress: string;
  votes: VoteCount;
  createdAt: string;
  updatedAt: string;
}

export interface VoteCount {
  upvotes: number;
  downvotes: number;
}

export interface Vote {
  subjectId: string;
  isUpvote: boolean;
  txHash?: string;
  timestamp: string;
}

export interface ApiResponse<T> {
  data: T;
  success: boolean;
  error?: string;
}
