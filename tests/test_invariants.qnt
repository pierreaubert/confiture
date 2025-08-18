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

  // Test: Funds conservation across deploy + block deduction (service balance + accounts sum to 25000)
  run test_funds_conservation = {
    init
    .then(deploy_service("alice", "hash_service", 2000, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "methodA", 50, 2)) // cost 100
    .then(produce_block)
    .expect(
      (
        accounts.keys().fold(0, (s, k) => s + accounts.get(k)) +
        services.keys().fold(0, (s, id) => s + services.get(id).balance)
      ) == 25000
    )
  }
}