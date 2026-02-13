# Confiture Protocol Specification in Quint

This project contains model to verify some algorithm or system used in the Polkadot ecosystem.

1. An analysis of Sassafras (concensus algorithm)
2. A very partial specification of the JAM (Join-Accumulate Machine) protocol

# Installing Quint

To run the specification and tests, you'll need to install Quint:

```bash
npm install -g @informalsystems/quint
```

or on MacOS:

```bash
brew install quint
```

# Sassafrass

To demonstrate the correctness of Polkadot's Sassafras (Secret Assignment of Sequential
Slots with Associated FRAS) consensus algorithm using the Quint specification language,
we need to model its core state machine and mathematically verify its guarantees.

## What are we verifying?

Sassafras is a Single Secret Leader Election (SSLE) protocol designed to replace the older
BABE protocol. It solves the following issues:

- Forks (Multiple Leaders): In BABE, two validators can independently win the same slot.
  Sassafras guarantees exactly one leader per slot.
- Empty Slots (Zero Leaders): In BABE, a slot might have no winner. Sassafras pre-sorts
  tickets to ensure continuous, constant-time block production.
- Targeted DoS Attacks: Sassafras keeps the slot leader’s identity a secret until the moment
  the block is published.

Because Quint (based on TLA+) verifies distributed system logic rather than raw cryptography,
we abstract the zk-SNARKs and Ring-VRFs. We assume the cryptographic primitives successfully
sort the tickets, and we use Quint to prove that the resulting protocol rules strictly guarantee
Safety (fork-freedom), Liveness (no empty slots), and Authorization.

## Running Tests

Checking invariants:
```bash
cd sassafras
quint run sassafras.qnt --invariant no_forks_inv
quint run sassafras.qnt --invariant constant_time_inv
```

Proving:
```bash
cd sassafras
quint verify sassafras.qnt --invariant valid_producer_inv --max-steps 100
quint verify sassafras.qnt --invariant constant_time_inv --max-steps 100
quint verify sassafras.qnt --invariant valid_producer_inv --max-steps 100
```

## Why this proves Sassafras is an upgrade over BABE

If you were to rewrite the sort_tickets action in this code to reflect BABE's Probabilistic
Leader Election—where VRF tickets are evaluated independently allowing Map().put(1, Set("Alice", "Bob"))
running quint verify would immediately fail.

It would spit out an error trace showing exactly how a chain fork occurred. By proving no_forks_inv under
Sassafras's global sorting constraints, Quint formally confirms that short-term forks are strictly impossible
by design.

# Jam

## Jam Overview

JAM is a trustless supercomputer that combines elements from both Polkadot and Ethereum, providing:
- Global singleton permissionless object environment (like Ethereum smart contracts)
- Secure sideband computation parallelized over a scalable node network (like Polkadot)
- Core-time allocation system for resource management
- Service deployment and execution framework

## Files

- `jam/confiture.qnt` - Main protocol specification
- `jam/tests/test_*.qnt` - A test suite
- `README.md` - This documentation

## Invariants Verified

1. **Financial Safety**
   - Account balances never go negative
   - Service balances remain non-negative
   - Active services maintain minimum balance

2. **Temporal Consistency**
   - Block numbers increase monotonically
   - Block timestamps are ordered correctly

3. **Resource Management**
   - Core schedules have no time conflicts
   - Gas limits are enforced per block

## Divergence with the JAM protocol

- All the id are integers. That make it easy to generate counters which you cannot do with strings in Quint.

### Added constraints and restrictions

- Number of validators is limited to a low number (configurable).
- Timestamp are not modelled properly
- Seals are not computed
- Funds are pre-defined with some users (Alive, Bob, Charlie, Treasury, ...)

### Known issues

- too many constants and random numbers in the Quint specifications esp. for gaz.
- too many invariant failures.

## Running Tests

Then run various test scenarios:

```bash
cd jam
# Type check tests
for t in tests/test_*.qnt; do
	quint typecheck "$t" >/dev/null 2>&1 && echo "✅" $t || echo "❌" $t
done

# Run tests
for t in tests/test_*.qnt; do
	quint run "$t" >/dev/null 2>&1 && echo "✅" $t || echo "❌" $t
done

# Run random execution to find violations
quint run confiture.qnt --max-steps=20

# Increase number of samples
quint run confiture.qnt --max-steps=20 --max-samples=100000

# Add invariant checking
quint run confiture.qnt --max-steps=20 --max-samples=100000 --invariant=system_invariant

# Run Apalache and verify
quint verify confiture.qnt
```

Note that verify works for some depth but then does not finish in a reasonable amount of time.

