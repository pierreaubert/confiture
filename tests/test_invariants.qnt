module test_invariants {
  import confiture.* from "../confiture"

  // Test: Invariants hold after a normal sequence of operations
  run test_invariants_after_operations = {
    init
    .then(deploy_service("alice", "hash_service", 1500, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "methodA", 100, 1))
    .then(produce_block)
    .expect(system_invariant)
  }

  // Test: Funds conservation across deploy + block deduction (service balance + state_basic.accounts sum to 25000)
  run test_funds_conservation = {
    init
    .then(deploy_service("alice", "hash_service", 2000, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "methodA", 50, 2)) // cost 100
    .then(produce_block)
    .expect(
      (
        state_basic.accounts.keys().fold(0, (s, k) => s + state_basic.accounts.get(k)) +
        state_basic.services.keys().fold(0, (s, id) => s + state_basic.services.get(id).balance)
      ) == 25000
    )
  }
}