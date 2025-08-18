module test_deploy_unknown_owner {
  import confiture.* from "../confiture"
  
  run test_deploy_unknown_owner = {
    init
    .then(deploy_service("dave", "hash_unknown", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(services.keys().size() == 0)
  }
}