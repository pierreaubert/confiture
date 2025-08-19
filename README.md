# Confiture Protocol Specification in Quint

This project contains a specification of the JAM (Join-Accumulate Machine) protocol written in Quint, a modern specification language based on TLA+.

## Overview

JAM is a trustless supercomputer that combines elements from both Polkadot and Ethereum, providing:
- Global singleton permissionless object environment (like Ethereum smart contracts)
- Secure sideband computation parallelized over a scalable node network (like Polkadot)
- Core-time allocation system for resource management
- Service deployment and execution framework

## Files

- `confiture.qnt` - Main protocol specification
- `tests/test_*.qnt` - A test suite
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

To run the specification and tests, you'll need to install Quint:

```bash
npm install -g @informalsystems/quint
```

or on MacOS:

```bash
brew install quint
```

Then run various test scenarios:

```bash
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

