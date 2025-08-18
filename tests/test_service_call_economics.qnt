module test_service_call_economics {
  import confiture.* from "../confiture"

  // Test: total_cost_for_caller and calls_affordable helper
  run test_call_cost_helpers = {
    init
    // Deploy to have a valid service
    .then(deploy_service("alice", "h", 1500, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "m1", 50, 2))   // 100
    .then(submit_service_call("alice", 0, "m2", 30, 3))   // 90
    .then(submit_service_call("bob", 0, "m3", 10, 5))     // 50
    .expect(and {
      // total expected spend if executed
      total_cost_for_caller(state_basic.pending_calls, "alice") == 190,
      total_cost_for_caller(state_basic.pending_calls, "bob") == 50,
      // Charlie no calls -> 0
      total_cost_for_caller(state_basic.pending_calls, "charlie") == 0,
      calls_affordable(state_basic.pending_calls, state_basic.accounts)
    })
  }

  // Test: calls_affordable false when one caller cannot afford
  run test_calls_affordable_false = {
    init
    .then(deploy_service("alice", "h", 1500, "r", "a", "m"))
    // Drain bob by hypothetical large call he can't afford
    .then(submit_service_call("bob", 0, "overspend", 20000, 1)) // cost 20000 > 10000
    .expect(not(calls_affordable(state_basic.pending_calls, state_basic.accounts)))
  }
}