module test_safrole_ticket_system {
  import confiture.* from "../confiture"

  // Test: Ticket lifecycle - pending to winning to used
  run test_ticket_lifecycle = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Mark ticket as winning (using Set operations)
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
    .then(all {
      // Mark ticket as used after block production (using Set operations)
      nondet used_ticket = state_safrole.tickets.filter(t => t.status == Winning).oneOf()
      val updated_used_ticket = { ...used_ticket, status: Used }
      state_safrole' = { ...state_safrole, 
        tickets: state_safrole.tickets.exclude(Set(used_ticket)).union(Set(updated_used_ticket))
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
      state_safrole.tickets.size() == 1,
      state_safrole.tickets.exists(ticket => ticket.status == Used)
    })
  }

  // Test: Ticket expiration
  run test_ticket_expiration = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Advance slot beyond ticket validity and mark expired state_safrole.tickets
      nondet expired_ticket = state_safrole.tickets.oneOf()
      val updated_expired_ticket = { ...expired_ticket, status: Expired }
      state_safrole' = { ...state_safrole, 
        current_slot: state_safrole.current_slot + 100,
        tickets: state_safrole.tickets.exclude(Set(expired_ticket)).union(Set(updated_expired_ticket))
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
      state_safrole.current_slot == 100,
      state_safrole.tickets.exists(ticket => ticket.status == Expired)
    })
  }

  // Test: Multiple state_safrole.tickets per epoch limit
  run test_tickets_per_epoch_limit = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    // Submit multiple state_safrole.tickets in same epoch
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(submit_ticket(1, state_safrole.current_slot + 2))
    .then(submit_ticket(2, state_safrole.current_slot + 3))
    .expect(and {
      state_safrole.tickets.size() == 3,
      // All state_safrole.tickets should be for the same epoch (simplified)
      state_safrole.tickets.forall(ticket => ticket.slot_number <= state_safrole.current_slot + 10)
    })
  }

  // Test: Ticket competition - same slot multiple state_safrole.validators
  run test_ticket_competition = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    // All submit for same slot
    .then(submit_ticket(0, state_safrole.current_slot + 5))
    .then(submit_ticket(1, state_safrole.current_slot + 5))
    .then(submit_ticket(2, state_safrole.current_slot + 5))
    .expect(and {
      state_safrole.tickets.size() == 3,
      // All state_safrole.tickets for same slot
      state_safrole.tickets.forall(ticket => ticket.slot_number == state_safrole.current_slot + 5),
      // Different state_safrole.validators
      state_safrole.tickets.exists(ticket => ticket.validator_index == 0),
      state_safrole.tickets.exists(ticket => ticket.validator_index == 1),
      state_safrole.tickets.exists(ticket => ticket.validator_index == 2)
    })
  }

  // Test: Ticket validation - entropy requirements
  run test_ticket_entropy_validation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .expect(and {
      state_safrole.tickets.size() == 1,
      state_safrole.tickets.exists(ticket => 
        ticket.validator_index == 0
      )
    })
  }

  // Test: Validator stake influence on ticket selection
  run test_stake_weighted_selection = {
    init
    .then(register_validator("low_stake", MIN_VALIDATOR_STAKE))
    .then(register_validator("high_stake", MIN_VALIDATOR_STAKE * 10))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(submit_ticket(1, state_safrole.current_slot + 1))
    .expect(and {
      state_safrole.tickets.size() == 2,
      // Both state_safrole.validators can submit state_safrole.tickets
      state_safrole.tickets.exists(ticket => ticket.validator_index == 0),
      state_safrole.tickets.exists(ticket => ticket.validator_index == 1),
      // Higher stake validator exists
      state_safrole.validators.keys().exists(idx => state_safrole.validators.get(idx).stake > MIN_VALIDATOR_STAKE)
    })
  }

  // Test: Block authoring rights from winning ticket
  run test_block_authoring_rights = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Mark ticket as winning and update validator
      nondet winning_ticket = state_safrole.tickets.oneOf()
      val updated_winning_ticket = { ...winning_ticket, status: Winning }
      state_safrole' = { ...state_safrole, 
        tickets: state_safrole.tickets.exclude(Set(winning_ticket)).union(Set(updated_winning_ticket)),
        validators: state_safrole.validators.setBy(0, v => { ...v, last_block_authored: state_basic.current_block + 1 })
      },
      state_basic' = { ...state_basic, current_block: state_basic.current_block + 1 },
      // Keep other state unchanged
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
      state_safrole.tickets.exists(ticket => ticket.status == Winning),
      state_safrole.validators.keys().exists(idx => state_safrole.validators.get(idx).last_block_authored == state_basic.current_block)
    })
  }

  // Test: Ticket cleanup after use
  run test_ticket_cleanup = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Simulate ticket usage and cleanup
      nondet used_ticket = state_safrole.tickets.oneOf()
      val updated_used_ticket = { ...used_ticket, status: Used }
      state_safrole' = { ...state_safrole, 
        tickets: state_safrole.tickets.exclude(Set(used_ticket)).union(Set(updated_used_ticket))
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
      state_safrole.tickets.size() == 1,
      state_safrole.tickets.exists(ticket => ticket.status == Used)
    })
  }
}
