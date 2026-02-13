module test_funds_conservation_block {
  import confiture.* from "../confiture"
  run test_funds_conservation_block = {
    init
    .then(deploy_service("alice", "svc_hash", 2000, "r","a","m"))
    .then(submit_service_call("alice", 0, "methodX", 100, 2)) // 200
    .then(produce_block)
    .expect(
      (
        state_basic.accounts.keys().fold(0, (s,k) => s + state_basic.accounts.get(k)) +
        state_basic.services.keys().fold(0, (s,id) => s + state_basic.services.get(id).balance)
      ) == 25000
    )
  }
}