module test_accumulate_batch_limit {
  import confiture.* from "../confiture"
  run test_accumulate_batch_limit = {
    init
    .then(deploy_service("alice", "batch_hash", MIN_SERVICE_BALANCE + 500, "r","a","m"))
    .then(submit_work_package(0, Set({ id:0, service_id:0, payload:"p0", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a0"))
    .then(refine_work_package(0))
    .then(submit_work_package(0, Set({ id:1, service_id:0, payload:"p1", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a1"))
    .then(refine_work_package(1))
    .then(submit_work_package(0, Set({ id:2, service_id:0, payload:"p2", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a2"))
    .then(refine_work_package(2))
    .then(submit_work_package(0, Set({ id:3, service_id:0, payload:"p3", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a3"))
    .then(refine_work_package(3))
    .then(submit_work_package(0, Set({ id:4, service_id:0, payload:"p4", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a4"))
    .then(refine_work_package(4))
    .then(submit_work_package(0, Set({ id:5, service_id:0, payload:"p5", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a5"))
    .then(refine_work_package(5))
    .then(submit_work_package(0, Set({ id:6, service_id:0, payload:"p6", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a6"))
    .then(refine_work_package(6))
    .then(submit_work_package(0, Set({ id:7, service_id:0, payload:"p7", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a7"))
    .then(refine_work_package(7))
    .then(submit_work_package(0, Set({ id:8, service_id:0, payload:"p8", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a8"))
    .then(refine_work_package(8))
    .then(submit_work_package(0, Set({ id:9, service_id:0, payload:"p9", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a9"))
    .then(refine_work_package(9))
    .then(submit_work_package(0, Set({ id:10, service_id:0, payload:"p10", gas_limit:1, status:WorkPending, refine_output:"", accumulate_input:"" }), "a10"))
    .then(refine_work_package(10))
    .then(accumulate_work_results(Set(0,1,2,3,4,5,6,7,8,9,10)))
    .expect(and {
      state_chain.jam_state_root != "state_accumulated",
      state_core.work_results.keys().size() == 11
    })
  }
}