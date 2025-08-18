module test_deploy_service_below_min {
  import confiture.* from "../confiture"
  run test_deploy_service_below_min = {
    init
    .then(deploy_service("alice", "low_hash", MIN_SERVICE_BALANCE - 1, "r","a","m"))
    .expect(services.keys().size() == 0)
  }
}