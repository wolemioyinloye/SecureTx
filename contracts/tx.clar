;; SecureTx - Confidential Transaction Wrapper
;; A privacy-preserving transaction wrapper that obfuscates transaction details

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_TRANSACTION_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_REVEALED (err u104))

;; Data Variables
(define-data-var transaction-counter uint u0)
(define-data-var protocol-fee uint u100) ;; 1% fee in basis points

;; Data Maps
(define-map confidential-transactions
  { tx-id: uint }
  {
    sender: principal,
    commitment: (buff 32),
    amount-hash: (buff 32),
    timestamp: uint,
    revealed: bool,
    fee-paid: uint
  }
)

(define-map transaction-nullifiers
  { nullifier: (buff 32) }
  { used: bool }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

;; Private Functions
(define-private (hash-amount (amount uint) (nonce (buff 32)))
  (sha256 (concat (unwrap-panic (to-consensus-buff? amount)) nonce))
)

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get protocol-fee)) u10000)
)

;; Read-only Functions
(define-read-only (get-transaction (tx-id uint))
  (map-get? confidential-transactions { tx-id: tx-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (is-nullifier-used (nullifier (buff 32)))
  (default-to false (get used (map-get? transaction-nullifiers { nullifier: nullifier })))
)

(define-read-only (get-transaction-count)
  (var-get transaction-counter)
)

;; Public Functions

;; Deposit function - users deposit STX to participate in confidential transactions
(define-public (deposit (amount uint))
  (let (
    (current-balance (get-user-balance tx-sender))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ current-balance amount) }
    )
    (ok amount)
  )
)

;; Create a confidential transaction commitment
(define-public (create-confidential-transaction 
  (commitment (buff 32)) 
  (amount-hash (buff 32)))
  (let (
    (tx-id (+ (var-get transaction-counter) u1))
    (fee (calculate-fee u1000)) ;; Base fee for creating transaction
    (current-balance (get-user-balance tx-sender))
  )
    (asserts! (>= current-balance fee) ERR_INSUFFICIENT_BALANCE)
    
    ;; Deduct fee from user balance
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance fee) }
    )
    
    ;; Store the confidential transaction
    (map-set confidential-transactions
      { tx-id: tx-id }
      {
        sender: tx-sender,
        commitment: commitment,
        amount-hash: amount-hash,
        timestamp: block-height,
        revealed: false,
        fee-paid: fee
      }
    )
    
    ;; Increment counter
    (var-set transaction-counter tx-id)
    
    (ok tx-id)
  )
)

;; Execute confidential transfer (simplified version)
(define-public (execute-confidential-transfer
  (tx-id uint)
  (recipient principal)
  (amount uint)
  (nonce (buff 32))
  (nullifier (buff 32)))
  (let (
    (tx-data (unwrap! (get-transaction tx-id) ERR_TRANSACTION_NOT_FOUND))
    (sender-balance (get-user-balance (get sender tx-data)))
    (recipient-balance (get-user-balance recipient))
    (expected-hash (hash-amount amount nonce))
  )
    ;; Verify the transaction hasn't been revealed yet
    (asserts! (not (get revealed tx-data)) ERR_ALREADY_REVEALED)
    
    ;; Verify the nullifier hasn't been used
    (asserts! (not (is-nullifier-used nullifier)) ERR_UNAUTHORIZED)
    
    ;; Verify the amount hash matches
    (asserts! (is-eq expected-hash (get amount-hash tx-data)) ERR_UNAUTHORIZED)
    
    ;; Verify sender has sufficient balance
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Mark nullifier as used
    (map-set transaction-nullifiers
      { nullifier: nullifier }
      { used: true }
    )
    
    ;; Update balances
    (map-set user-balances
      { user: (get sender tx-data) }
      { balance: (- sender-balance amount) }
    )
    
    (map-set user-balances
      { user: recipient }
      { balance: (+ recipient-balance amount) }
    )
    
    ;; Mark transaction as revealed
    (map-set confidential-transactions
      { tx-id: tx-id }
      (merge tx-data { revealed: true })
    )
    
    (ok true)
  )
)

;; Withdraw function - users can withdraw their balance
(define-public (withdraw (amount uint))
  (let (
    (current-balance (get-user-balance tx-sender))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok amount)
  )
)

;; Admin function to update protocol fee
(define-public (set-protocol-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT) ;; Max 10% fee
    (var-set protocol-fee new-fee)
    (ok new-fee)
  )
)