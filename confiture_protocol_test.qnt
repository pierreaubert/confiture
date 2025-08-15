// JAM Protocol Test Suite
// Tests for the JAM protocol specification

module jam_protocol_test {
  import jam_protocol.*
  
  // ============================================================================
  // TEST SCENARIOS
  // ============================================================================
  
  // Test: Basic service deployment with JAM entry points
  run deploy_service_test = {
    init
    .then(deploy_service("alice", "test_code", 2000, "refine_fn", "accumulate_fn", "on_message_fn"))
    .then(all {
      assert(services.keys().size() == 1),
      assert(services.get(1).owner == "alice"),
      assert(services.get(1).balance == 2000),
      assert(services.get(1).refine_code == "refine_fn"),
      assert(services.get(1).accumulate_code == "accumulate_fn"),
      assert(services.get(1).on_message_code == "on_message_fn"),
      assert(accounts.get("alice") == 8000)  // 10000 - 2000
    })
  }
  
  // Test: Work package submission and processing
  run work_package_test = {
    init
    .then(deploy_service("alice", "test_code", 2000, "refine_fn", "accumulate_fn", "on_message_fn"))
    .then(all {
      val work_item = {
        id: 1,
        service_id: 1,
        payload: "test_payload",
        gas_limit: 100,
        status: Pending,
        refine_output: "",
        accumulate_input: ""
      }
      val work_items = Set(work_item)
      submit_work_package(1, work_items, "auth_hash")
    })
    .then(all {
      assert(pending_work_packages.size() > 0),
      assert(work_packages.keys().size() > 0)
    })
  }

  // Test: Work package refinement
  run work_refinement_test = {
    init
    .then(deploy_service("alice", "test_code", 2000, "refine_fn", "accumulate_fn", "on_message_fn"))
    .then(all {
      val work_item = {
        id: 1,
        service_id: 1,
        payload: "test_payload",
        gas_limit: 100,
        status: Pending,
        refine_output: "",
        accumulate_input: ""
      }
      val work_items = Set(work_item)
      submit_work_package(1, work_items, "auth_hash")
    })
    .then(refine_work_package(1))
    .then(all {
      assert(work_results.keys().size() > 0),
      assert(work_results.get(1).success == true)
    })
  }

  // Test: Service deployment with insufficient funds
  run deploy_service_insufficient_funds_test = {
    init
    .then(deploy_service("charlie", "test_code", 6000, "refine", "accumulate", "message"))  // Charlie only has 5000
    .fail()  // This should fail
  }
  
  // Test: Core time purchase
  run purchase_core_time_test = {
    init
    .then(deploy_service("alice", "test_code", 2000))
    .then(purchase_core_time("alice", 1, 0, 6000, 1000, 500))
    .then(all {
      assert(accounts.get("alice") == 7500),  // 10000 - 2000 - 500
      assert(core_schedule.get(0).has(6000)),
      assert(core_schedule.get(0).get(6000) == 1)
    })
  }
  
  // Test: Service call submission
  run submit_service_call_test = {
    init
    .then(deploy_service("alice", "test_code", 2000))
    .then(submit_service_call("bob", 1, "transfer", "100", 1000, 5))
    .then(all {
      assert(pending_calls.size() == 1),
      val call = pending_calls.oneOf()
      assert(call.caller == "bob"),
      assert(call.service_id == 1),
      assert(call.method == "transfer")
    })
  }
  
  // Test: Block production
  run block_production_test = {
    init
    .then(deploy_service("alice", "test_code", 2000))
    .then(submit_service_call("bob", 1, "transfer", "100", 1000, 5))
    .then(produce_block)
    .then(all {
      assert(current_block == 1),
      assert(blocks.has(1)),
      assert(pending_calls.size() == 0),  // Call should be processed
      assert(accounts.get("bob") == 5000)  // 10000 - 1000*5 = 5000
    })
  }
  
  // Test: Service termination
  run service_termination_test = {
    init
    .then(deploy_service("alice", "test_code", 2000))
    .then(terminate_service(1, "alice"))
    .then(all {
      assert(services.get(1).state == Terminated),
      assert(accounts.get("alice") == 10000)  // Balance restored
    })
  }
  
  // Test: Unauthorized service termination should fail
  run unauthorized_termination_test = {
    init
    .then(deploy_service("alice", "test_code", 2000))
    .then(terminate_service(1, "bob"))  // Bob trying to terminate Alice's service
    .fail()
  }
  
  // ============================================================================
  // PROPERTY-BASED TESTS
  // ============================================================================
  
  // Test: System invariants hold after random operations
  run invariant_preservation_test = {
    init
    .then(step)
    .then(step)
    .then(step)
    .then(step)
    .then(step)
    .then(assert(system_invariant))
  }
  
  // Test: Account balances conservation
  run balance_conservation_test = {
    init
    .then(all {
      val initial_total = accounts.keys().fold(0, (sum, acc) => sum + accounts.get(acc))
      assert(initial_total == 25000)  // alice: 10000, bob: 10000, charlie: 5000
    })
    .then(deploy_service("alice", "test_code", 2000))
    .then(all {
      // Total should still be 25000 (money moved from alice account to service)
      val alice_balance = accounts.get("alice")
      val service_balance = services.get(1).balance
      val total_in_accounts = accounts.keys().fold(0, (sum, acc) => sum + accounts.get(acc))
      val total_in_services = services.keys().fold(0, (sum, id) => sum + services.get(id).balance)
      assert(total_in_accounts + total_in_services == 25000)
    })
  }
  
  // ============================================================================
  // STRESS TESTS
  // ============================================================================
  
  // Test: Multiple services deployment
  run multiple_services_test = {
    init
    .then(deploy_service("alice", "code1", 1500))
    .then(deploy_service("bob", "code2", 2000))
    .then(deploy_service("charlie", "code3", 1000))
    .then(all {
      assert(services.size() == 3),
      assert(next_service_id == 4),
      assert(services.keys() == Set(1, 2, 3))
    })
  }
  
  // Test: Core scheduling conflicts
  run core_conflict_test = {
    init
    .then(deploy_service("alice", "code1", 2000))
    .then(deploy_service("bob", "code2", 2000))
    .then(purchase_core_time("alice", 1, 0, 6000, 2000, 500))
    .then(purchase_core_time("bob", 2, 0, 7000, 1000, 300))  // Overlapping time
    .fail()  // Should fail due to conflict
  }
  
  // Test: Gas limit enforcement
  run gas_limit_test = {
    init
    .then(deploy_service("alice", "test_code", 5000))
    // Submit calls that exceed block gas limit
    .then(submit_service_call("alice", 1, "method1", "args", 8000000, 1))
    .then(submit_service_call("alice", 1, "method2", "args", 8000000, 1))
    .then(produce_block)
    .then(all {
      // Only one call should be included due to gas limit
      assert(blocks.get(1).service_calls.size() <= 1)
    })
  }

  // Test: JAM block creation and structure
  run jam_block_creation_test = {
    init
    .then(all {
      // Check genesis block exists
      assert(blocks.keys().contains(0)),
      assert(chain_head == 0),
      val genesis = blocks.get(0)
      assert(genesis.header.block_number == 0),
      assert(genesis.header.parent_hash == "0x0000000000000000000000000000000000000000000000000000000000000000")
    })
    .then(deploy_service("alice", "test_code", 1000, "refine", "accumulate", "on_message"))
    .then(submit_extrinsic(Transfer, "transfer_data", "alice"))
    .then(produce_block)
    .then(all {
      // Check that block was created
      assert(chain_head == 1),
      assert(blocks.keys().contains(1)),
      // Check block structure
      val block = blocks.get(1)
      assert(block.header.block_number == 1),
      assert(block.header.parent_hash == "genesis_hash"),
      assert(block.extrinsics.size() >= 1),
      // Check that pending extrinsics were cleared
      assert(pending_extrinsics.size() == 0)
    })
  }

  // Test: Extrinsic submission
  run extrinsic_submission_test = {
    init
    .then(submit_extrinsic(Governance, "governance_proposal", "bob"))
    .then(all {
      assert(pending_extrinsics.size() == 1),
      assert(next_extrinsic_id == 2),
      val extrinsic = pending_extrinsics.head()
      assert(extrinsic.extrinsic_type == Governance),
      assert(extrinsic.author == "bob"),
      assert(extrinsic.data == "governance_proposal")
    })
  }
}

// ============================================================================
// TEMPORAL PROPERTIES
// ============================================================================

module jam_temporal_properties {
  import jam_protocol.*
  
  // Eventually, all pending calls get processed
  temporal eventually_all_calls_processed = 
    always(pending_calls.size() > 0 implies eventually(pending_calls.size() == 0))
  
  // Services remain active until explicitly terminated
  temporal service_persistence = 
    always(services.keys().forall(id => {
      val service = services.get(id)
      service.state == Active implies 
        (service.state == Active).until(service.state == Terminated)
    }))
  
  // Block numbers increase monotonically
  temporal monotonic_blocks = 
    always(current_block' >= current_block)
  
  // Account balances can only decrease through legitimate operations
  temporal balance_legitimacy = 
    always(accounts.keys().forall(acc => 
      accounts.get(acc)' < accounts.get(acc) implies 
        (// Service deployment
         services.keys().exists(id => services.get(id).owner == acc) or
         // Core time purchase  
         core_schedule.keys().exists(core => 
           core_schedule.get(core).keys().exists(time => true)) or
         // Service call payment
         pending_calls.exists(call => call.caller == acc))
    ))
}
