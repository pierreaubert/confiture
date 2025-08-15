# Confiture Protocol Specification in Quint

This project contains a part of the formal specification of the JAM (Join-Accumulate Machine) protocol written in Quint, a modern specification language based on TLA+.

## Overview

JAM is a trustless supercomputer that combines elements from both Polkadot and Ethereum, providing:
- Global singleton permissionless object environment (like Ethereum smart contracts)
- Secure sideband computation parallelized over a scalable node network (like Polkadot)
- Core-time allocation system for resource management
- Service deployment and execution framework

## Files

- `confiture_protocol.qnt` - Main protocol specification
- `confiture_protocol_test.qnt` - Comprehensive test suite
- `README.md` - This documentation

## Key Components Modeled

### 1. **Service Management**
- Service deployment with owner authentication
- Service states: Inactive, Active, Suspended, Terminated
- Balance management and minimum funding requirements

### 2. **Core Time Allocation**
- Purchase of computation time on specific cores
- Conflict detection and resolution
- Time-based scheduling system

### 3. **Service Execution**
- Service call submission and queuing
- Gas-based execution model
- Block production with call processing

### 4. **State Management**
- Account balances and transfers
- Service storage (key-value pairs)
- Block chain with monotonic timestamps

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

Then run various test scenarios:

```bash
# Run basic deployment test
quint run confiture_protocol_test.qnt --run=deploy_service_test

# Run invariant preservation test
quint run confiture_protocol_test.qnt --run=invariant_preservation_test

# Check system invariants
quint run confiture_protocol.qnt --invariant=system_invariant

# Run random execution to find violations
quint run confiture_protocol.qnt --max-steps=20
```

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
