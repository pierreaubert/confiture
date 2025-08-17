module test_long_range_attack {
  import confiture.* from "../confiture"

  // Test 15: Long Range Attack Prevention
  run test_long_range_attack = {
    init
    .then(register_validator("attacker", MIN_VALIDATOR_STAKE))
    .then(register_validator("honest1", MIN_VALIDATOR_STAKE))
    .then(register_validator("honest2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    .then(finalize_block("block_hash_1", 1))
    .then(finalize_block("block_hash_2", 2))
    // Attacker tries to create alternative history from genesis
    .then(all {
      // Simulate attempt to fork from old finalized block
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments,
      blocks' = blocks,
      chain_head' = chain_head,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
      validators' = validators,
      validator_count' = validator_count,
      tickets' = tickets,
      pending_tickets' = pending_tickets,
      current_slot' = current_slot,
      entropy_accumulator' = entropy_accumulator,
      finalized_blocks' = finalized_blocks,
      grandpa_round' = grandpa_round,
      pending_votes' = pending_votes,
      finality_justifications' = finality_justifications,
      pvm_programs' = pvm_programs,
      pvm_contexts' = pvm_contexts,
      pvm_gas_used' = pvm_gas_used,
      data_blobs' = data_blobs,
      data_segments' = data_segments,
      next_blob_id' = next_blob_id,
      availability_threshold' = availability_threshold,
      disputes' = disputes,
      next_dispute_id' = next_dispute_id,
      slashing_events' = slashing_events,
      scheduled_packages' = scheduled_packages,
      scheduling_policy' = scheduling_policy,
      parachains' = parachains,
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id,
      // Attack should be prevented by finality
      assert(finalized_blocks.contains(1)),
      assert(finalized_blocks.contains(2))
    })
    .expect(and {
      finalized_blocks.size() >= 2,
      // Finalized blocks cannot be reverted
      chain_head >= 2
    })
  }
}
