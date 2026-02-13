module test_deploy_service_insufficient_funds {
  import confiture.* from "../confiture"
  
  run test_deploy_service_insufficient_funds = {
    init
    .then(deploy_service("alice", "huge_hash", 9999999, "r", "a", "m"))
    .expect(state_basic.services.keys().size() == 0)
  }
}