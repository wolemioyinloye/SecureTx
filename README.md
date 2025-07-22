# SecureTx - Confidential Transaction Wrapper

SecureTx is a privacy-preserving smart contract built on Stacks that enables confidential transactions through cryptographic commitments and nullifiers. It allows users to transact while keeping transaction amounts and details private from external observers.

## Features

- **Confidential Transactions**: Hide transaction amounts using cryptographic commitments
- **Nullifier System**: Prevent double-spending while maintaining privacy
- **Deposit/Withdraw**: Secure fund management with STX integration
- **Fee Management**: Configurable protocol fees with admin controls
- **Privacy Preservation**: Transaction details remain confidential until execution

## How It Works

1. **Deposit**: Users deposit STX into the contract to participate in confidential transactions
2. **Commitment Creation**: Create a cryptographic commitment to a transaction amount and details
3. **Confidential Transfer**: Execute transfers using zero-knowledge proofs and nullifiers
4. **Withdrawal**: Withdraw remaining balance back to STX

## Contract Functions

### Public Functions

#### `deposit(amount: uint)`
Deposits STX into the contract for use in confidential transactions.

#### `create-confidential-transaction(commitment: buff, amount-hash: buff)`
Creates a new confidential transaction commitment with encrypted amount and details.

#### `execute-confidential-transfer(tx-id: uint, recipient: principal, amount: uint, nonce: buff, nullifier: buff)`
Executes a confidential transfer by revealing the commitment and verifying proofs.

#### `withdraw(amount: uint)`
Withdraws STX from the user's contract balance.

#### `set-protocol-fee(new-fee: uint)` [Admin Only]
Updates the protocol fee (max 10%).

### Read-Only Functions

#### `get-transaction(tx-id: uint)`
Returns transaction details for a given transaction ID.

#### `get-user-balance(user: principal)`
Returns the contract balance for a specific user.

#### `is-nullifier-used(nullifier: buff)`
Checks if a nullifier has been used to prevent double-spending.

#### `get-transaction-count()`
Returns the total number of confidential transactions created.

## Usage Example

```clarity
;; Deposit 1000 STX
(contract-call? .securetx deposit u1000000) ;; 1000 STX in microSTX

;; Create confidential transaction
(contract-call? .securetx create-confidential-transaction 
  0x1234567890abcdef... ;; commitment hash
  0xabcdef1234567890... ;; amount hash
)

;; Execute confidential transfer
(contract-call? .securetx execute-confidential-transfer
  u1              ;; transaction ID
  'SP1234...      ;; recipient
  u500000         ;; amount (500 STX)
  0x9876543210... ;; nonce
  0xfedcba0987... ;; nullifier
)
```

## Security Considerations

- **Commitment Scheme**: Uses SHA256 for amount commitments with nonces
- **Nullifier Prevention**: Prevents double-spending through unique nullifiers
- **Balance Verification**: Ensures users have sufficient funds before transfers
- **Access Control**: Admin functions restricted to contract owner
- **Fee Protection**: Maximum fee cap prevents excessive charges

## Privacy Features

- Transaction amounts are hidden until execution
- Sender and recipient relationships are obfuscated
- Nullifiers prevent transaction graph analysis
- Commitments use cryptographic hashing for privacy

## Limitations

- This is a simplified implementation for demonstration purposes
- Production use would require additional zero-knowledge proof verification
- Enhanced privacy features like ring signatures could be added
- Gas optimization and batch processing not implemented

## Testing

Deploy the contract to a local Stacks testnet and test the following scenarios:

1. Deposit and withdrawal flows
2. Confidential transaction creation
3. Successful and failed transfer execution
4. Nullifier reuse prevention
5. Balance verification

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request


## Disclaimer

This contract is for educational and demonstration purposes. Audit thoroughly before any production use. The privacy guarantees depend on proper implementation of zero-knowledge proofs and secure key management by users.