module test_deploy_drain_account {
  import confiture.* from "../confiture"
  run test_deploy_drain_account = {
    init
    .then(deploy_service("alice", "h1", 2500, "r","a","m"))
    .then(deploy_service("alice", "h2", 2500, "r","a","m"))
    .then(deploy_service("alice", "h3", 2500, "r","a","m"))
    .then(deploy_service("alice", "h4", 2500, "r","a","m"))
    .then(deploy_service("alice", "h5", 2500, "r","a","m")) // should fail
    .expect(and {
      services.keys().size() == 4,
      accounts.get("alice") == 10000 - 4 * 2500
    })
  }
}