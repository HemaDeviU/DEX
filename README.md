## Decentralized Exchange - Automatic Market Maker

This project aims to create a simplified Decentralized Exchange using the automatic market maker algorithm to swap between two ERC20 tokens.

### Requirements
- #### Foundry

To get started with Foundry, run the following commands:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
git clone https://github.com/HemaDeviU/DEX
cd dex
forge build
```

### Usage
- #### For local Deployment

1.  Start a local node
```make anvil```
2.  Deploy
```make deploy```

- #### For testnet deployment

1. Setup environment variables
You'll want to set your SEPOLIA_RPC_URL and PRIVATE_KEY as environment variables. You can add them to a .env file.

- PRIVATE_KEY: The private key of your account (like from metamask) which has testnet ETH.
- SEPOLIA_RPC_URL: This is url of the sepolia testnet node you're working with. You can get setup with one for free from Alchemy.
- ETHERSCAN_API_KEY: To verify the contract,get the api key from etherscan account.

2. Deploy
make deploy ARGS="--network sepolia"







