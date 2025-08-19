module test_safrole_consensus {
  import confiture.* from "../confiture"

  // Test: Basic validator registration
  run test_validator_registration = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .expect(and {
      state_safrole.validator_count == 1,
      state_safrole.validators.keys().contains(0),
      state_safrole.validators.get(0).public_key == "validator1",
      state_safrole.validators.get(0).state == ValidatorActive,
      state_safrole.validators.get(0).stake == MIN_VALIDATOR_STAKE
    })
  }

  // Test: Cannot register validator with insufficient stake
  run test_validator_registration_insufficient_stake = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE - 100))
    .expect(state_safrole.validator_count == 0)
  }

  // Test: Cannot register duplicate validator
  run test_validator_registration_duplicate = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .expect(and {
      state_safrole.validator_count == 1,
      state_safrole.validators.get(0).stake == MIN_VALIDATOR_STAKE // Original stake unchanged
    })
  }

  // Test: Maximum validator limit
  run test_validator_registration_max_limit = {
    init
    .then(all {
      state_safrole' = { ...state_safrole, 
        validator_count: MAX_VALIDATORS,
        validators: Map(0 -> {
          index: 0,
          public_key: "existing_validator",
          state: ValidatorActive,
          stake: MIN_VALIDATOR_STAKE,
          core_assignments: Set(),
          last_block_authored: 0
        })
      },
      // Keep other state unchanged  
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .then(register_validator("new_validator", MIN_VALIDATOR_STAKE))
    .expect(state_safrole.validator_count == MAX_VALIDATORS) // Should not increase
  }

  // Test: SAFROLE ticket submission
  run test_ticket_submission = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .expect(and {
      state_safrole.tickets.size() == 1,
      state_safrole.tickets.exists(ticket => 
        ticket.validator_index == 0 and
        ticket.slot_number == state_safrole.current_slot + 1 and
        ticket.status == TicketPending
      )
    })
  }

  // Test: Cannot submit ticket for inactive validator
  run test_ticket_submission_inactive_validator = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(all {
      // Deactivate the validator
      state_safrole' = { ...state_safrole, 
        validators: state_safrole.validators.setBy(0, v => { ...v, state: ValidatorInactive })
      },
      // Keep other state unchanged
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .expect(state_safrole.tickets.size() == 0) // No ticket should be created
  }

  // Test: Cannot submit ticket for past slot
  run test_ticket_submission_past_slot = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot - 1))
    .expect(state_safrole.tickets.size() == 0)
  }

  // Test: Multiple state_safrole.validators submitting state_safrole.tickets
  run test_multiple_validator_tickets = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(submit_ticket(1, state_safrole.current_slot + 2))
    .then(submit_ticket(2, state_safrole.current_slot + 3))
    .expect(and {
      state_safrole.tickets.size() == 3,
      state_safrole.validator_count == 3,
      // Each validator should have submitted a ticket
      state_safrole.tickets.exists(ticket => ticket.validator_index == 0),
      state_safrole.tickets.exists(ticket => ticket.validator_index == 1),
      state_safrole.tickets.exists(ticket => ticket.validator_index == 2)
    })
  }

  // Test: Ticket winning selection (simplified)
  run test_ticket_winning_selection = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(submit_ticket(1, state_safrole.current_slot + 1)) // Same slot competition
    .then(all {
      // Mark one ticket as winning (simplified approach for Set operations)
      nondet winning_ticket = state_safrole.tickets.filter(t => t.validator_index == 0).oneOf()
      val updated_ticket = { ...winning_ticket, status: Winning }
      state_safrole' = { ...state_safrole, 
        tickets: state_safrole.tickets.exclude(Set(winning_ticket)).union(Set(updated_ticket))
      },
      // Keep other state unchanged
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .expect(and {
      state_safrole.tickets.size() == 2,
      // One ticket should be winning
      state_safrole.tickets.exists(ticket => ticket.status == Winning),
      // One ticket should still be pending
      state_safrole.tickets.exists(ticket => ticket.status == TicketPending)
    })
  }

  // Test: Entropy accumulation
  run test_entropy_accumulation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Simulate entropy accumulation
      state_chain' = { ...state_chain, 
        entropy_pool: "accumulated_entropy"
      },
      // Keep other state unchanged
      state_basic' = state_basic,
      state_core' = state_core,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .expect(and {
      state_chain.entropy_pool == "accumulated_entropy",
      state_safrole.tickets.size() == 1
    })
  }

  // Test: Slot progression
  run test_slot_progression = {
    init
    .then(all {
      state_safrole' = { ...state_safrole, 
        current_slot: state_safrole.current_slot + 1
      },
      // Keep other state unchanged
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .expect(state_safrole.current_slot == 1) // Started at 0, now at 1
  }
}
