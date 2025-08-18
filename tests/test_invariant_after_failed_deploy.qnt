module test_invariant_after_failed_deploy {
  import confiture.* from "../confiture"
  run test_invariant_after_failed_deploy = {
    init
    .then(deploy_service("alice", "fail", 9999999, "r","a","m"))
    .expect(system_invariant)
  }
}