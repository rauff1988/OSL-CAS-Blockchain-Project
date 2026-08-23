# OSL — Open Source Lottery

Academic project submitted for the CAS Blockchain & Decentralized Application Development, University of Geneva.

## Project purpose

OSL is a Solidity-based academic prototype exploring how a transparent lottery mechanism could use smart contracts for:

- participant registration;
- automated prize and fee distribution;
- OSL token rewards;
- charity-governance voting by OSL token holders.

The prototype was developed and demonstrated using Remix IDE and the Remix VM.

## Important limitation

This repository contains an educational prototype only. It is **not production-ready** and must not be used with real funds.

In particular, the prototype uses block-derived pseudo-randomness for demonstration purposes. A production implementation would require secure verifiable randomness, such as Chainlink VRF, professional security auditing, regulatory analysis, licensing where applicable, AML/KYC controls, and a full user-interface and backend architecture.

## Contracts

| File | Purpose |
|---|---|
| `OSLToken.sol` | ERC-20 utility token named Open Source Lottery (OSL), with a fixed maximum supply of 1,000,000 OSL. |
| `Lottery.sol` | Demonstration lottery contract: three participants each enter with 1 ETH; the contract selects one winner and distributes the pool. |
| `CharityGovernance.sol` | Allows OSL token holders to vote on charity causes using their OSL token balance as voting power. |

## Prototype economics

For the three-player Remix demonstration:

- Entry fee: 1 ETH per participant
- Maximum participants: 3
- Total pool: 3 ETH
- Winner payout: 95% (2.85 ETH)
- Charity allocation: 3% (0.09 ETH)
- Project allocation: 2% (0.06 ETH)
- Participant OSL reward: 1 OSL per valid entry, subject to the contract’s configured OSL/USD price logic
- Winner OSL reward: an additional 5 OSL, subject to the same price logic

## Deployment order in Remix

1. Compile `OSLToken.sol` and deploy `OSLToken`.
2. Copy the deployed OSL token address.
3. Compile and deploy `CharityGovernance.sol`, using the OSL token address as constructor input.
4. Compile and deploy `Lottery.sol`, using:
   - the OSL token address;
   - a charity wallet address;
   - a project-fee wallet address.
5. From the deployer account, configure the OSL price with `setOSLPriceUSD(...)`.
6. Use three separate participant accounts to call `register()` with exactly 1 ETH each.
7. Call `selectWinner()` from the owner/deployer account.
8. Check ETH payouts and OSL token balances.
9. Use an account holding OSL to call `vote("Health")` or another cause in `CharityGovernance`.

## Technology

- Solidity
- OpenZeppelin ERC-20, Ownable and ReentrancyGuard components
- Remix IDE / Remix VM
- Ethereum-compatible smart-contract environment

## Author

Rauf Hinder  
CAS Blockchain & Decentralized Application Development  
University of Geneva
