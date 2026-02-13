# Why do we need BEEFY?

Polkadot’s primary finality gadget, GRANDPA, is incredibly fast and secure, but its
cryptographic proofs are extremely complex. If you want an Ethereum Smart Contract (or a Light Client)
to verify GRANDPA consensus, the gas fees would be high. BEEFY runs alongside GRANDPA as an adapter.
Once GRANDPA finalizes a block, the validators sign a highly compressed MMR Root (Merkle Mountain Range)
using standard Ethereum-friendly cryptography (ECDSA/secp256k1). If an external Relayer can prove to
the Ethereum Smart Contract that a Supermajority ($> \frac{2}{3}$) of Polkadot validators signed the
exact same MMR Root, Ethereum accepts it as absolute truth without needing to sync the whole chain.

# Verification

```shell
quint verify beefy.qnt --invariant bridge_safety_inv
quint verify beefy.qnt --invariant single_finality_inv
```

# Why it works:
In Quint, signatures is defined as a mathematical Set. Sets inherently enforce uniqueness. If the malicious validator M1 furiously executes malicious_sign millions of times to spam the network, the signatures Set still only registers exactly 1 signature for M1.

Because you cannot forge another validator's private key, FAKE_MMR is mathematically capped at a signature size of 1. The Ethereum smart contract strictly demands THRESHOLD = 3. Therefore, the relay_to_light_client action for the fake payload is forever blocked. The bridge is perfectly safe.

# How to Hack the Bridge (Testing the limits of BFT)

To truly demonstrate the value of formal verification, let's test what happens if a protocol architect writes a flawed Ethereum Smart Contract that lowers the threshold requirements.

Change THRESHOLD to 1 in your code and run again.
