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
# Run basic deployment test
for t in tests/test_*.qnt; do
	quint run "$t.qnt"

# Run random execution to find violations
quint run confiture.qnt --max-steps=20

# Run Apalache and verify
quint verify confiture.qnt
```

Note that verify works for some depth but then does finish.

## Test Scenarios Included

- **Basic Operations**: Service deployment, core time purchase, service calls
- **Error Cases**: Insufficient funds, unauthorized operations, scheduling conflicts
- **Property Tests**: Invariant preservation, balance conservation
- **Stress Tests**: Multiple services, gas limit enforcement
- **Temporal Properties**: Eventually consistency, service persistence

## Architecture Highlights

The specification models JAM as a state machine with:
- **1024 cores** available for computation
- **6-second block time**
- **15M gas limit** per block
- **Minimum 1000 unit balance** for active services

## Formal Verification

The Quint specification can be used with:
- **Apalache** for bounded model checking
- **TLC** for exhaustive state exploration
- **Quint simulator** for random execution testing

This provides mathematical guarantees about protocol correctness and helps identify potential issues before implementation.
