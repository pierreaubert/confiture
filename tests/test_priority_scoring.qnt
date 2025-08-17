module test_priority_scoring {
  import confiture.* from "../confiture"

  // Test 9: Priority Score Calculation
  run test_priority_scoring = {
    init
    .expect(and {
      val high_priority_pkg = {
        package: {
          id: 1, service_id: 1, work_items: Set(), authorization: "",
          context: create_work_context(0, "", ""), status: WorkPending,
          core_assignment: 0, gas_limit: 1000, gas_consumed: 0
        },
        priority: High, submission_time: 0, gas_fee: 10000, submitter_stake: 100000
      }
      val low_priority_pkg = {
        package: {
          id: 2, service_id: 1, work_items: Set(), authorization: "",
          context: create_work_context(0, "", ""), status: WorkPending,
          core_assignment: 0, gas_limit: 500, gas_consumed: 0
        },
        priority: Low, submission_time: 0, gas_fee: 1000, submitter_stake: 10000
      }
      priority_score(high_priority_pkg) > priority_score(low_priority_pkg)
    })
  }
}
