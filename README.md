Learning from uniswap source code
1. to avoid gas cost from reverting transactions, need to simulate computations to get expected output before running critical logics
2. to support easy onchain / offchain data sync, build pure helper functions
3. to write safe code, set the invariants & responsibility for each module / function clearly