# Trifecta DeFi Protocol

A DeFi protocol that integrates with Uniswap V3 for optimal token swaps, featuring custom ERC20 tokens and NFT rewards.

## Contracts

### TrifectaToken (ERC20)
- Custom ERC20 token with minting capabilities
- Role-based access control for minting
- ERC20Permit functionality for gasless approvals

### TrifectaNFT (ERC721)
- Custom NFT implementation with URI storage
- Role-based minting control
- Metadata support via URI storage

### TrifectaSwap
- Uniswap V3 integration for token swaps
- Automatic best pool detection based on liquidity
- Support for exact input and exact output swaps
- Slippage protection

## Setup

1. Install dependencies:
```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.1
forge install Uniswap/v3-core@v1.0.0
forge install Uniswap/v3-periphery@v1.3.0
```

2. Set up environment variables:
```bash
export ETH_RPC_URL=your_ethereum_rpc_url
export ETHERSCAN_API_KEY=your_etherscan_api_key
```

3. Build the project:
```bash
forge build
```

4. Run tests:
```bash
forge test
```

## Usage

### Token Operations
- Mint new tokens (requires MINTER_ROLE)
- Transfer tokens
- Use permit for gasless approvals

### NFT Operations
- Mint new NFTs with custom URIs (requires MINTER_ROLE)
- Transfer NFTs
- View NFT metadata

### Swap Operations
1. Find best liquidity pool for a token pair
2. Execute exact input swaps
3. Execute exact output swaps

## Testing

The project includes comprehensive tests for all contracts:
- Token functionality tests
- NFT minting and transfer tests
- Swap integration tests using forked mainnet

## Security

- Role-based access control for privileged operations
- Slippage protection for swaps
- Reentrancy protection
- Standard security practices from OpenZeppelin

## License

MIT
