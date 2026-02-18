# GRANDPA Finality Gadget

GRANDPA (GHOST-based Recursive ANcestor Deriving Prefix Agreement) is Polkadot's
finality gadget. Unlike traditional BFT protocols that finalize blocks one at a time,
GRANDPA can finalize entire chains of blocks at once by having validators vote on the
highest block they consider final. All ancestors of a finalized block are implicitly
finalized too.

This model (`grandpa_v3`) captures the protocol faithfully based on the
[GRANDPA paper](https://research.web3.foundation/Polkadot/protocols/finality) by
Stewart et al., including:

- **Primary proposer** with round-robin selection and timer-based fallback
- **Tolerant vote counting** that accounts for equivocators (pessimistic counting per the paper)
- **Proper GHOST** that walks the block tree from `last_finalized`, descending through children with supermajority support
- **Nil precommits** when the GHOST doesn't extend the last finalized block
- **Round completability** and timer-based round advancement without finalization
- **Commit messages** broadcast on finalization
- **Catch-up protocol** for validators that fall behind

## Round Lifecycle

```
WaitingForPrimary --> PrevotePhase --> PrecommitPhase --> FinalizePhase
       |                                                       |
       |  (primary broadcasts estimate,                        |  (finalize if supermajority
       |   others receive or timeout)                          |   precommits, or advance
       |                                                       |   round on timer + completable)
       +<------------------------------------------------------+
```

## Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| N | 4 | Total validators |
| F | 1 | Maximum Byzantine faults |
| THRESHOLD | 3 | Supermajority ($> \frac{2}{3}N$) |
| MAX_ROUND | 3 | Maximum round number |
| MAX_HEIGHT | 4 | Maximum block tree depth |
| MAX_CLOCK | 10 | Logical clock bound |
| TIMER_THRESHOLD | 2 | Time units before primary timeout |

## Verification

```shell
# Typecheck
quint typecheck grandpa.qnt

# Safety: no two finalized blocks at the same height
quint run grandpa.qnt --main=grandpa_v3 --max-steps=10 --invariant=safety

# Accountable safety: safety violation implies > F equivocators
quint run grandpa.qnt --main=grandpa_v3 --max-steps=10 --invariant=accountable_safety

# No honest validator equivocates
quint run grandpa.qnt --main=grandpa_v3 --max-steps=10 --invariant=no_honest_equivocation

# GHOST always extends last finalized block
quint run grandpa.qnt --main=grandpa_v3 --max-steps=10 --invariant=ghost_extends_finalized

# All commit messages have valid supermajority
quint run grandpa.qnt --main=grandpa_v3 --max-steps=10 --invariant=valid_commits
```

## Tolerant Vote Counting

A critical correctness aspect from the GRANDPA paper: when counting votes for a block,
equivocators (validators who cast conflicting votes) are pessimistically counted as
voting for *every* block. This ensures that the GHOST computation remains safe even
in the presence of Byzantine validators, because the protocol never underestimates
the support any block might have.

## How to Break Safety

To test the limits of BFT, increase `F` so that `MALICIOUS` validators exceed $\frac{1}{3}N$.
For example, set `F = 2` with `N = 4` and run the safety invariant to see a counterexample
where two conflicting blocks get finalized.
