module test_calls_affordable_true {
  import confiture.* from "../confiture"
  run test_calls_affordable_true = {
    init
    .then(deploy_service("alice", "aff_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_service_call("alice", 0, "m1", 50, 2))   // 100
    .then(submit_service_call("alice", 0, "m2", 30, 3))   // 90
    .then(submit_service_call("bob", 0, "m3", 10, 5))     // 50
    .expect(and {
      total_cost_for_caller(pending_calls, "alice") == 190,
      total_cost_for_caller(pending_calls, "bob") == 50,
      total_cost_for_caller(pending_calls, "charlie") == 0,
      calls_affordable(pending_calls, accounts)
    })
  }
}