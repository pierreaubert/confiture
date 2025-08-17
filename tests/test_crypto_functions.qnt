module test_crypto_functions {
  import confiture.* from "../confiture"

  // Test 2: Cryptographic functions
  run test_crypto_functions = {
    init
    .expect(and {
      compute_hash(Blake2b, "test") == "blake2b_hash",
      verify_signature(Ed25519, "pubkey", "message", "sig_valid") == true,
      verify_signature(Ed25519, "pubkey", "message", "invalid") == false
    })
  }
}
