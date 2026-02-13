//                                                                          -*- quint -*-

module beefy {
  // --- TYPES & CONSTANTS ---
  type Validator = str
  type Payload = str
  type Signature = { payload: Payload, signer: Validator }

  // We model a BFT network with 3 Honest Validators and 1 Malicious Validator (N=4).
  pure val HONEST: Set[Validator] = Set("H1", "H2", "H3")
  pure val MALICIOUS: Set[Validator] = Set("M1")
  pure val VALIDATORS: Set[Validator] = HONEST.union(MALICIOUS)

  // Supermajority threshold: > 2/3 of the validator set.
  // For N=4, 2/3 is 2.66. Thus, a valid BEEFY commitment strictly requires 3 signatures.
  pure val THRESHOLD: int = 3

  // We model two scenarios: the valid MMR root finalized by GRANDPA, and a malicious forged MMR root.
  pure val VALID_MMR: Payload = "GRANDPA_FINALIZED_MMR"
  pure val FAKE_MMR: Payload = "FAKE_MALICIOUS_MMR"

  // --- STATE VARIABLES ---
  var signatures: Set[Signature]            // The public mempool of broadcasted BEEFY signatures
  var bridge_light_client: Set[Payload]     // The payloads accepted by the remote chain (e.g., Ethereum)

  // --- INITIALIZATION ---
  action init = all {
    signatures' = Set(),
    bridge_light_client' = Set(),
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Action 1: Honest validators EXCLUSIVELY sign the valid MMR handed down by GRANDPA.
  action honest_sign = {
    nondet h = HONEST.oneOf()
    all {
      signatures' = signatures.union(Set({ payload: VALID_MMR, signer: h })),
      bridge_light_client' = bridge_light_client,
    }
  }

  // Action 2: Malicious validators attempt to trick the Ethereum bridge by signing a FAKE MMR.
  action malicious_sign = {
    nondet m = MALICIOUS.oneOf()
    all {
      signatures' = signatures.union(Set({ payload: FAKE_MMR, signer: m })),
      bridge_light_client' = bridge_light_client,
    }
  }

  // Action 3: Relayers transport the signatures to the Ethereum Light Client Smart Contract.
  action relay_to_light_client = {
    nondet p = Set(VALID_MMR, FAKE_MMR).oneOf()

    // The smart contract counts the unique signers for this specific payload
    val signers_for_payload = signatures.filter(s => s.payload == p).map(s => s.signer)

    all {
      // SMART CONTRACT RULE: Enforce the supermajority threshold
      signers_for_payload.size() >= THRESHOLD,
      not(bridge_light_client.contains(p)), // Only relay if not already accepted

      bridge_light_client' = bridge_light_client.union(Set(p)),
      signatures' = signatures,
    }
  }

  // Action 4: Stuttering step to avoid deadlocks
  action idle = all {
    signatures' = signatures,
    bridge_light_client' = bridge_light_client,
  }

  action step = any {
    honest_sign,
    malicious_sign,
    relay_to_light_client,
    idle,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Property 1: Bridge Safety (No forged blocks are EVER accepted by Ethereum)
  // Ensures the bridge cannot be hacked by malicious validators feeding it bad state.
  val bridge_safety_inv =
    not(bridge_light_client.contains(FAKE_MMR))

  // Property 2: Unique Finality
  // The light client must never accept conflicting states simultaneously.
  val single_finality_inv =
    bridge_light_client.size() <= 1
}