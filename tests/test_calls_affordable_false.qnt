module test_calls_affordable_false {
  import confiture.* from "../confiture"
  run test_calls_affordable_false = {
    init
    .then(deploy_service("alice", "aff_false_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_service_call("bob", 0, "overspend", 20000, 1)) // > bob balance
    .expect(not(calls_affordable(pending_calls, accounts)))
  }
}