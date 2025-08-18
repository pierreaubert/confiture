module test_funds_conservation_block {
  import confiture.* from "../confiture"
  run test_funds_conservation_block = {
    init
    .then(deploy_service("alice", "svc_hash", 2000, "r","a","m"))
    .then(submit_service_call("alice", 0, "methodX", 100, 2)) // 200
    .then(produce_block)
    .expect(
      (
        accounts.keys().fold(0, (s,k) => s + accounts.get(k)) +
        services.keys().fold(0, (s,id) => s + services.get(id).balance)
      ) == 25000
    )
  }
}