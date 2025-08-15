// JAM Protocol Specification in Quint (Final Version)
// Join-Accumulate Machine: A trustless supercomputer combining Polkadot and Ethereum elements

module jam_protocol {
  // ============================================================================
  // TYPES AND CONSTANTS
  // ============================================================================
  
  type ServiceState = Inactive | Active | Suspended | Terminated
  type CoreState = Available | Occupied | Disputed
  type WorkItemStatus = Pending | InProgress | Refined | Accumulated | Failed
  
  // Core JAM Service definition with entry points
  type Service = {
    id: int,
    owner: str,
    code_hash: str,
    state: ServiceState,
    balance: int,
    // Service entry points
    refine_code: str,      // fn refine() - in-core execution
    accumulate_code: str,  // fn accumulate() - on-chain execution  
    on_message_code: str   // on_message() - inter-service messaging
  }
  
  // Work Package - collection of work items for a service
  type WorkPackage = {
    id: int,
    service_id: int,
    work_items: Set[WorkItem],
    core_index: int,
    authorization_hash: str,
    context: WorkContext
  }
  
  // Work Item - individual unit of work
  type WorkItem = {
    id: int,
    service_id: int,
    payload: str,
    gas_limit: int,
    status: WorkItemStatus,
    refine_output: str,    // Output from refine phase
    accumulate_input: str  // Input to accumulate phase
  }
  
  // Work Result - output from work package processing
  type WorkResult = {
    package_id: int,
    service_id: int,
    core_index: int,
    refined_outputs: Set[str],
    accumulate_data: str,
    gas_used: int,
    success: bool
  }
  
  // Core - execution environment for work packages
  type Core = {
    index: int,
    state: CoreState,
    current_package: int,  // Work package ID being processed
    validator_set: Set[str], // Validators assigned to this core
    time_allocated: int
  }
  
  // Work Context - execution context for work packages
  type WorkContext = {
    block_number: int,
    timestamp: int,
    entropy: str,
    prior_state_root: str
  }

  // JAM Block Header - contains block metadata and commitments
  type BlockHeader = {
    parent_hash: str,           // Hash of the parent block
    block_number: int,          // Sequential block number
    state_root: str,            // Root of the JAM state trie
    extrinsics_root: str,       // Root of extrinsics trie
    entropy_pool_root: str,     // Current entropy accumulator
    timestamp: int,             // Block timestamp
    epoch: int,                 // Current epoch number
    winning_tickets: Set[str],  // Winning lottery tickets for this block
    offenders_markers: Set[str], // Markers for validator offenses
    author_index: int,          // Index of the block author
    seal: str                   // Block seal/signature
  }

  // JAM Block - complete block structure
  type Block = {
    header: BlockHeader,
    extrinsics: Set[Extrinsic],
    guarantees: Set[Guarantee],
    assurances: Set[Assurance],
    preimages: Set[Preimage],
    availability: Set[AvailabilityAttestation]
  }

  // Extrinsic - external transaction or operation
  type Extrinsic = {
    id: int,
    extrinsic_type: ExtrinsicType,
    data: str,
    signature: str,
    author: str
  }

  type ExtrinsicType = Transfer | ServiceCallExtrinsic | WorkPackageSubmission | Governance

  // Guarantee - validator guarantee for work package execution
  type Guarantee = {
    work_package_hash: str,
    core_index: int,
    validator_index: int,
    signature: str,
    timeslot: int
  }

  // Assurance - assurance of work package availability
  type Assurance = {
    work_package_hash: str,
    assurer_index: int,
    signature: str,
    bitfield: str  // Availability bitfield
  }

  // Preimage - data preimage for work packages
  type Preimage = {
    hash: str,
    data: str,
    length: int
  }

  // Availability Attestation - attestation of data availability
  type AvailabilityAttestation = {
    core_index: int,
    validator_index: int,
    availability_bitfield: str,
    signature: str
  }
  
  // Legacy service call for backward compatibility
  type ServiceCall = {
    caller: str,
    service_id: int,
    method: str,
    gas_limit: int,
    gas_price: int
  }
  
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  // State variables
  var current_block: int
  var services: int -> Service
  var accounts: str -> int
  var pending_calls: Set[ServiceCall]
  var next_service_id: int

  // JAM-specific state
  var cores: int -> Core
  var work_packages: int -> WorkPackage
  var work_results: int -> WorkResult
  var pending_work_packages: Set[WorkPackage]
  var next_package_id: int
  var next_work_item_id: int
  
  // JAM State
  var jam_state_root: str
  var entropy_pool: str
  var validator_assignments: int -> Set[str]  // core_index -> validator_set

  // Blockchain state
  var blocks: int -> Block
  var chain_head: int
  var current_epoch: int
  var pending_extrinsics: Set[Extrinsic]
  var next_extrinsic_id: int
  
  // Protocol constants
  pure val MAX_GAS_PER_BLOCK = 15000000
  pure val MIN_SERVICE_BALANCE = 1000
  pure val TOTAL_CORES = 341  // JAM protocol specifies 341 cores
  pure val CORE_INDICES = 0.to(TOTAL_CORES - 1)
  pure val MAX_WORK_ITEMS_PER_PACKAGE = 16
  pure val VALIDATORS = Set("val1", "val2", "val3", "val4", "val5", "val6")  // Simplified validator set
  
  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================
  
  // Calculate total cost for a caller across a set of calls
  pure def total_cost_for_caller(calls: Set[ServiceCall], caller: str): int =
    calls.filter(call => call.caller == caller)
         .fold(0, (acc, call) => acc + call.gas_limit * call.gas_price)
  
  // Check if a set of calls can be afforded by all callers
  pure def calls_affordable(calls: Set[ServiceCall], account_balances: str -> int): bool =
    Set("alice", "bob", "charlie").forall(caller =>
      account_balances.get(caller) >= total_cost_for_caller(calls, caller)
    )
  
  // JAM-specific helper functions
  
  // Calculate total gas for work items in a package
  pure def package_gas_total(items: Set[WorkItem]): int =
    items.fold(0, (acc, work_item) => acc + work_item.gas_limit)
  
  // Check if a core is available for assignment
  pure def core_available(core: Core): bool =
    core.state == Available
  
  // Get available cores
  pure def available_cores(core_map: int -> Core): Set[int] =
    CORE_INDICES.filter(i => core_available(core_map.get(i)))
  
  // Create work context for current block
  pure def create_work_context(block_num: int, entropy: str, state_root: str): WorkContext =
    { block_number: block_num, timestamp: block_num * 6000, entropy: entropy, prior_state_root: state_root }

  // Create genesis block
  pure def create_genesis_block(): Block = {
    val genesis_header = {
      parent_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      block_number: 0,
      state_root: "genesis_state",
      extrinsics_root: "empty_extrinsics",
      entropy_pool_root: "initial_entropy",
      timestamp: 0,
      epoch: 0,
      winning_tickets: Set(),
      offenders_markers: Set(),
      author_index: 0,
      seal: "genesis_seal"
    }
    {
      header: genesis_header,
      extrinsics: Set(),
      guarantees: Set(),
      assurances: Set(),
      preimages: Set(),
      availability: Set()
    }
  }

  // Create block header for new block
  pure def create_block_header(parent_hash: str, block_num: int, state_root: str, entropy_root: str, timestamp: int, epoch: int): BlockHeader = {
    parent_hash: parent_hash,
    block_number: block_num,
    state_root: state_root,
    extrinsics_root: "extrinsics_root",
    entropy_pool_root: entropy_root,
    timestamp: timestamp,
    epoch: epoch,
    winning_tickets: Set(),
    offenders_markers: Set(),
    author_index: 0,
    seal: "block_seal"
  }
  
  // ============================================================================
  // INITIAL STATE
  // ============================================================================
  
  action init = all {
    current_block' = 0,
    services' = Map(),
    accounts' = Map("alice" -> 10000, "bob" -> 10000, "charlie" -> 5000),
    pending_calls' = Set(),
    next_service_id' = 1,
    
    // Initialize cores
    cores' = CORE_INDICES.mapBy(i => {
      index: i,
      state: Available,
      current_package: 0,
      validator_set: Set(),
      time_allocated: 0
    }),
    
    // Initialize JAM-specific state
    work_packages' = Map(),
    work_results' = Map(),
    pending_work_packages' = Set(),
    next_package_id' = 1,
    next_work_item_id' = 1,
    
    // Initialize JAM state
    jam_state_root' = "genesis_state",
    entropy_pool' = "initial_entropy",
    validator_assignments' = CORE_INDICES.mapBy(_ => Set()),

    // Initialize blockchain state
    blocks' = Map(0 -> {
      header: {
        parent_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        block_number: 0,
        state_root: "genesis_state",
        extrinsics_root: "empty_extrinsics",
        entropy_pool_root: "initial_entropy",
        timestamp: 0,
        epoch: 0,
        winning_tickets: Set(),
        offenders_markers: Set(),
        author_index: 0,
        seal: "genesis_seal"
      },
      extrinsics: Set(),
      guarantees: Set(),
      assurances: Set(),
      preimages: Set(),
      availability: Set()
    }),
    chain_head' = 0,
    current_epoch' = 0,
    pending_extrinsics' = Set(),
    next_extrinsic_id' = 1
  }
  
  // ============================================================================
  // ACTIONS
  // ============================================================================
  
  // Deploy a new JAM service with entry points
  action deploy_service(owner: str, code_hash: str, initial_balance: int, refine_code: str, accumulate_code: str, on_message_code: str): bool = {
    val can_deploy = and {
      accounts.keys().contains(owner),
      accounts.get(owner) >= initial_balance,
      initial_balance >= MIN_SERVICE_BALANCE
    }
    val new_service = {
      id: next_service_id,
      owner: owner,
      code_hash: code_hash,
      state: Active,
      balance: initial_balance,
      refine_code: refine_code,
      accumulate_code: accumulate_code,
      on_message_code: on_message_code
    }
    
    all {
      can_deploy,
      services' = services.put(next_service_id, new_service),
      accounts' = accounts.setBy(owner, balance => balance - initial_balance),
      next_service_id' = next_service_id + 1,
      current_block' = current_block,
      pending_calls' = pending_calls,
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
      next_extrinsic_id' = next_extrinsic_id
    }
  }
  
  // ============================================================================
  // JAM WORK PACKAGE ACTIONS
  // ============================================================================
  
  // Submit a work package for processing
  action submit_work_package(service_id: int, work_items: Set[WorkItem], authorization: str): bool = {
    val service_exists = services.keys().contains(service_id)
    val service = if (service_exists) services.get(service_id) else { 
      id: 0, owner: "", code_hash: "", state: Inactive, balance: 0, 
      refine_code: "", accumulate_code: "", on_message_code: "" 
    }
    val total_gas = package_gas_total(work_items)
    val available_core_set = available_cores(cores)
    val can_submit = and {
      service_exists,
      service.state == Active,
      work_items.size() <= MAX_WORK_ITEMS_PER_PACKAGE,
      work_items.size() > 0,
      total_gas <= MAX_GAS_PER_BLOCK,
      available_core_set.size() > 0
    }
    val selected_core = if (can_submit and available_core_set.size() > 0) available_core_set.fold(0, (acc, core) => core) else 0
    val work_context = create_work_context(current_block, entropy_pool, jam_state_root)
    val new_package = {
      id: next_package_id,
      service_id: service_id,
      work_items: work_items,
      core_index: selected_core,
      authorization_hash: authorization,
      context: work_context
    }
    all {
      can_submit,
      pending_work_packages' = pending_work_packages.union(Set(new_package)),
      next_package_id' = next_package_id + 1,
      // Reserve the core
      cores' = cores.setBy(selected_core, core => { ...core, state: Occupied, current_package: next_package_id }),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      work_packages' = work_packages,
      work_results' = work_results,
      next_work_item_id' = next_work_item_id,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments
    }
  }
  
  // Refine phase - execute work items in-core
  action refine_work_package(package_id: int): bool = {
    val package_exists = pending_work_packages.exists(pkg => pkg.id == package_id)
    val work_package = if (package_exists) 
      pending_work_packages.filter(pkg => pkg.id == package_id).fold({id: 0, service_id: 0, work_items: Set(), core_index: 0, authorization_hash: "", context: {block_number: 0, timestamp: 0, entropy: "", prior_state_root: ""}}, (acc, pkg) => pkg) 
      else { id: 0, service_id: 0, work_items: Set(), core_index: 0, authorization_hash: "", context: create_work_context(0, "", "") }
    val service_exists = services.keys().contains(work_package.service_id)
    val service = if (service_exists) services.get(work_package.service_id) else { 
      id: 0, owner: "", code_hash: "", state: Inactive, balance: 0, 
      refine_code: "", accumulate_code: "", on_message_code: "" 
    }
    val can_refine = and {
      package_exists,
      service_exists,
      service.state == Active,
      cores.get(work_package.core_index).state == Occupied
    }
    // Simulate refine execution - in real implementation this would execute service.refine_code
    val refined_items = work_package.work_items.map(wi => 
      { ...wi, status: Refined, refine_output: "refined_output" }
    )
    val refined_package = { ...work_package, work_items: refined_items }
    val work_result = {
      package_id: package_id,
      service_id: work_package.service_id,
      core_index: work_package.core_index,
      refined_outputs: refined_items.map(work_item => work_item.refine_output),
      accumulate_data: "accumulate_input",
      gas_used: package_gas_total(work_package.work_items),
      success: true
    }
    all {
      can_refine,
      work_packages' = work_packages.put(package_id, refined_package),
      work_results' = work_results.put(package_id, work_result),
      pending_work_packages' = pending_work_packages.exclude(Set(work_package)),
      // Free the core
      cores' = cores.setBy(work_package.core_index, core => { ...core, state: Available, current_package: 0 }),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments
    }
  }
  
  // Accumulate phase - process refined results on-chain
  action accumulate_work_results(result_ids: Set[int]): bool = {
    val results_exist = result_ids.forall(id => work_results.keys().contains(id))
    val can_accumulate = and {
      results_exist,
      result_ids.size() > 0,
      result_ids.size() <= 10  // Limit accumulation batch size
    }
    val results_to_process = result_ids.map(id => work_results.get(id))
    val total_gas_used = results_to_process.fold(0, (acc, result) => acc + result.gas_used)
    // Simulate accumulate execution - in real implementation this would execute service.accumulate_code
    val new_state_root = "state_accumulated"
    all {
      can_accumulate,
      jam_state_root' = new_state_root,
      entropy_pool' = entropy_pool,  // Keep entropy_pool unchanged for now
      // Mark work items as accumulated
      work_packages' = result_ids.fold(work_packages, (packages, result_id) => {
        val result = work_results.get(result_id)
        val package = packages.get(result.package_id)
        val accumulated_items = package.work_items.map(wi => 
          if (result_ids.contains(wi.id)) { ...wi, status: Accumulated }
          else wi
        )
        packages.setBy(result.package_id, pkg => { ...pkg, work_items: accumulated_items })
      }),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      validator_assignments' = validator_assignments
    }
  }
  
  // Legacy service call for backward compatibility
  action submit_service_call(caller: str, service_id: int, method: str, gas_limit: int, gas_price: int): bool = {
    val can_call = and {
      accounts.keys().contains(caller),
      services.keys().contains(service_id),
      services.get(service_id).state == Active,
      accounts.get(caller) >= gas_limit * gas_price
    }
    val new_call = {
      caller: caller,
      service_id: service_id,
      method: method,
      gas_limit: gas_limit,
      gas_price: gas_price
    }
    
    all {
      can_call,
      pending_calls' = pending_calls.union(Set(new_call)),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
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
      next_extrinsic_id' = next_extrinsic_id
    }
  }
  
  // Produce a new JAM block with work package processing
  action produce_block: bool = {
    val new_block_number = current_block + 1
    val new_timestamp = new_block_number * 6000  // 6 second block time
    
    // Process legacy service calls and convert to extrinsics
    val executable_calls = pending_calls.filter(call =>
      calls_affordable(Set(call), accounts)
    )
    val gas_limited_calls = executable_calls.filter(call => call.gas_limit <= MAX_GAS_PER_BLOCK)
    val total_gas = gas_limited_calls.fold(0, (acc, call) => acc + call.gas_limit)
    val final_calls = if (total_gas <= MAX_GAS_PER_BLOCK) gas_limited_calls else Set()
    
    // Convert service calls to extrinsics
    val service_call_extrinsics = final_calls.map(call => {
      id: next_extrinsic_id,
      extrinsic_type: ServiceCallExtrinsic,
      data: call.method,
      signature: "sig_caller",
      author: call.caller
    })
    
    // Process pending work packages (refine phase happens automatically)
    val packages_to_refine = pending_work_packages.filter(pkg => 
      cores.get(pkg.core_index).state == Occupied
    )
    
    // Update entropy and state root for new block
    val new_entropy = "entropy_updated"
    val new_state_root = "state_block_updated"
    val parent_hash = if (current_block == 0) "genesis_hash" else "block_hash_prev"
    
    // Create new block header
    val new_header = create_block_header(parent_hash, new_block_number, new_state_root, new_entropy, new_timestamp, current_epoch)
    
    // Create new block
    val new_block = {
      header: new_header,
      extrinsics: service_call_extrinsics.union(pending_extrinsics),
      guarantees: Set(),  // TODO: Add guarantees from work package processing
      assurances: Set(),  // TODO: Add assurances
      preimages: Set(),   // TODO: Add preimages
      availability: Set() // TODO: Add availability attestations
    }
    
    all {
      current_block' = new_block_number,
      chain_head' = new_block_number,
      blocks' = blocks.put(new_block_number, new_block),
      pending_calls' = pending_calls.exclude(final_calls),
      pending_extrinsics' = Set(),
      next_extrinsic_id' = next_extrinsic_id + service_call_extrinsics.size(),
      accounts' = final_calls.fold(accounts, (acc_map, call) =>
        acc_map.setBy(call.caller, balance => balance - call.gas_limit * call.gas_price)
      ),
      // Update JAM state
      entropy_pool' = new_entropy,
      jam_state_root' = new_state_root,
      // Unchanged state
      services' = services,
      next_service_id' = next_service_id,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch
    }
  }
  
  // Submit an extrinsic to the mempool
  action submit_extrinsic(extrinsic_type: ExtrinsicType, data: str, author: str): bool = {
    val can_submit = accounts.keys().contains(author)
    val new_extrinsic = {
      id: next_extrinsic_id,
      extrinsic_type: extrinsic_type,
      data: data,
      signature: "sig_author",
      author: author
    }
    
    all {
      can_submit,
      pending_extrinsics' = pending_extrinsics.union(Set(new_extrinsic)),
      next_extrinsic_id' = next_extrinsic_id + 1,
      // Unchanged state
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
      current_epoch' = current_epoch
    }
  }

  // Terminate a service
  action terminate_service(service_id: int, caller: str): bool = {
    val service_exists = services.keys().contains(service_id)
    val service = if (service_exists) services.get(service_id) else { 
      id: 0, owner: "", code_hash: "", state: Inactive, balance: 0, 
      refine_code: "", accumulate_code: "", on_message_code: "" 
    }
    val can_terminate = and {
      service_exists,
      service.owner == caller,
      service.state == Active
    }
    all {
      can_terminate,
      services' = services.setBy(service_id, s => { ...s, state: Terminated, balance: 0 }),
      accounts' = accounts.setBy(caller, balance => balance + service.balance),
      current_block' = current_block,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      // JAM state unchanged
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments
    }
  }
  
  // ============================================================================
  // SYSTEM STEP
  // ============================================================================
  
  action step: bool = any {
    // Service deployment
    all {
      nondet caller = accounts.keys().oneOf()
      deploy_service(caller, "code_hash", 1000, "refine_code", "accumulate_code", "on_message_code")
    },
    // Legacy service call
    all {
      services.keys().size() > 0,
      nondet caller = accounts.keys().oneOf()
      nondet service_id = services.keys().oneOf()
      nondet gas_limit = 1.to(100).oneOf()
      nondet gas_price = 1.to(10).oneOf()
      submit_service_call(caller, service_id, "call_data", gas_limit, gas_price)
    },
    // Work package submission
    all {
      services.keys().size() > 0,
      nondet service_id = services.keys().oneOf()
      nondet gas_limit = 10.to(100).oneOf()
      val work_item = {
        id: next_work_item_id,
        service_id: service_id,
        payload: "payload",
        gas_limit: gas_limit,
        status: Pending,
        refine_output: "",
        accumulate_input: ""
      }
      val work_items = Set(work_item)
      submit_work_package(service_id, work_items, "auth_hash")
    },
    // Work package refinement
    all {
      work_packages.keys().size() > 0,
      nondet package_id = work_packages.keys().oneOf()
      refine_work_package(package_id)
    },
    // Work result accumulation
    all {
      val available_results = work_results.keys().filter(id => 
        work_results.get(id).success == true
      )
      all {
        available_results.size() > 0,
        nondet result_id = available_results.oneOf()
        val result_ids = Set(result_id)
        accumulate_work_results(result_ids)
      }
    },
    // Extrinsic submission
    all {
      nondet caller = accounts.keys().oneOf()
      nondet extrinsic_type = Set(Transfer, Governance).oneOf()
      submit_extrinsic(extrinsic_type, "extrinsic_data", caller)
    },
    // Block production
    produce_block,
    // Service termination
    all {
      services.keys().size() > 0,
      nondet caller = accounts.keys().oneOf()
      nondet service_id = services.keys().oneOf()
      terminate_service(service_id, caller)
    }
  }
  
  // ============================================================================
  // INVARIANTS
  // ============================================================================
  
  // Account balances should never be negative
  val accounts_non_negative = 
    accounts.keys().forall(account => accounts.get(account) >= 0)
  
  // Service balances should never be negative
  val service_balances_non_negative = 
    services.keys().forall(id => services.get(id).balance >= 0)
  
  // Active services should have minimum balance
  val active_services_funded = 
    services.keys().forall(id => {
      val service = services.get(id)
      service.state != Active or service.balance >= MIN_SERVICE_BALANCE
    })
  
  // Block numbers should be monotonic
  val blocks_monotonic = current_block >= 0
  
  // Conservation of funds - total money in system should remain constant
  val total_funds = 
    accounts.keys().fold(0, (sum, acc) => sum + accounts.get(acc)) +
    services.keys().fold(0, (sum, id) => sum + services.get(id).balance)
  
  val funds_conservation = total_funds == 25000  // Initial total: 10000 + 10000 + 5000
  
  // Total system invariant
  val system_invariant = and {
    accounts_non_negative,
    service_balances_non_negative,
    active_services_funded,
    blocks_monotonic,
    funds_conservation
  }
}
