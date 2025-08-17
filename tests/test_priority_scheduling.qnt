module test_priority_scheduling {
  import confiture.* from "../confiture"

  // Test 8: Advanced Work Package Scheduling
  run test_priority_scheduling = {
    init
    .then(deploy_service("alice", "service_code", 2000, "refine", "accumulate", "message"))
    .then(submit_prioritized_work_package(1, Set({
      id: 1, service_id: 1, payload: "high_priority", gas_limit: 1000,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth1", High, 5000))
    .then(submit_prioritized_work_package(1, Set({
      id: 2, service_id: 1, payload: "low_priority", gas_limit: 500,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth2", Low, 1000))
    .expect(and {
      scheduled_packages.size() == 2,
      scheduling_policy == PriorityBased,
      scheduled_packages.exists(pkg => pkg.priority == High)
    })
  }
}
