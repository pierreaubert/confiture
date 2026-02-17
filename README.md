# Confiture Protocol Specification in Quint

This project contains models to verify some algorithms or system used in the Polkadot ecosystem.

If Sassafras determines who builds a block, and ELVES mathematically guarantees how the block's
execution is verified, BEEFY is the protocol that allows Polkadot to securely export this finality
to external blockchains (like Ethereum via Snowbridge).

1. [Sassafras](https://wiki.polkadot.com/learn/learn-safrole/)
2. [Elves](https://wiki.polkadot.com/learn/learn-safrole/)
3. [BEEFY](https://research.web3.foundation/Polkadot/protocols/BEEFY)
4. [GRANDPA](https://research.web3.foundation/Polkadot/protocols/finality)

5. A very partial specification of the JAM (Join-Accumulate Machine) protocol

# Installing Quint

To run the specification and tests, you'll need to install Quint:

```bash
npm install -g @informalsystems/quint
```

or on MacOS:

```bash
brew install quint
```

# Jump into the relevant directory

## [Sassafras](sassafras/README.md)
## [Elves](elves/README.md)
## [Beefy](beefy/README.md)
## [Grandpa](grandpa/README.md)
## [Jam](jam/README.md)

