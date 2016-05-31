# TIME

define :res do Rational('1/8') end

define :verbosity do 1 end

live_loop :main do
  use_bpm 150
  use_cue_logging (verbosity > 1) ? true : false
  use_debug (verbosity > 0) ? true : false
  wait res
  root = _state.get_state :root
  if root.nil?
    puts "[ERROR] no root state"
    next
  end
  t = tick
  dispatch_grid root, t, {}
end

# DISPATCH

define :dispatch_grid do |grid, t, inherited_params, inherited_type=nil, inherited_type_value=nil|
  bpc = Rational(grid[:bpc])
  tpc = bpc / res
  boundary = t % tpc.ceil
  i = (t / tpc).ceil
  if verbosity > 2
    puts "[DEBUG] t: #{t} bpc: #{bpc} tpc: #{tpc} boundary: #{boundary} i: #{i}"
  end
  grid[:tracks].each_index do |index|
    track = grid[:tracks][index]
    type = track[:type]
    if type.nil?
      puts "[ERROR] missing type #{track}"
      next
    end
    on = (bools *track[:beats].map{|x|x[0]})[i]
    if type == "grid"
      if not on
        next
      end
      grid_type = grid[:'grid-type']
      id = track[:id].to_sym
      sub_grid = _state[id]
      if grid_type = "synth"
        params = track[:'synth-params']
        params = inherited_params.merge(params)
        grid_synth = track[:'grid-synth']
        dispatch_grid sub_grid, t, params, grid_type, grid_synth
      elsif grid_type = "sample"
        params = track[:'sample-params']
        params = inherited_params.merge(params)
        grid_sample = track[:'grid-sample']
        dispatch_grid sub_grid, t, params, grid_type, grid_sample
      else
        dispatch_grid sub_grid, t, inherted_params
      end
    else
      params = track[:params]
      params = inherited_params.merge(params)
      if boundary == 0 and on
        dispatch_track track, params, index, inherited_type, inherited_type_value
      end
    end
  end
end

define :dispatch_track do |track, inherited_params, index, inherited_type=nil, inherited_type_value=nil|

  if verbosity > 2
    puts "[DEBUG] dispatching track #{track}"
  end

  type = track[:type]
  if type.nil?
    puts "[ERROR] no type for track #{track}"
    return
  end

  if type == "none" and inherited_type
    type = inherited_type
  end

  inherited_params.each do |key, value|
    if value.start_with?("\\")
      materialized_value = eval value[1..-1], get_binding(index)
      inherited_params[key] = materialized_value
    end
  end

  if type == "sample"
    sample = track[:sample]
    if sample.nil?
      if not inherited_type_value
        return
      end
      sample = inherited_type_value
    end
    s = sample.to_sym
    if s.nil?
      puts "[ERROR] no sample for track #{track}"
      return
    end
    thunk = lambda { sample s, **inherited_params }
    fx_chain = track[:fx]
    if fx_chain.nil?
      fx_chain = []
    end
    apply_fx fx_chain, thunk
    return
  end

  if type == "play"
    n = track[:note]
    if n.nil?
      return
    end
    play n, **inherited_params
    return
  end

  if type == "synth"
    synth = track[:synth]
    if synth.nil?
      if not inherited_type_value
        return
      end
      synth = inherited_type_value
    end
    s = synth.to_sym
    if s.nil?
      puts "[ERROR] no synth for track #{track}"
      return
    end
    thunk = lambda { synth s, **inherited_params }
    fx_chain = track[:fx]
    if fx_chain.nil?
      fx_chain = []
    end
    apply_fx fx_chain, thunk
    return
  end
end

define :get_binding do |index|
  return binding
end

define :apply_fx do |fx_chain, thunk|
  if fx_chain.length == 0
    thunk.call()
  else
    fx = fx_chain[0]
    fx_chain = fx_chain[1..-1]
    with_fx fx[:fx], **fx[:params] do
      apply_fx fx_chain, thunk
    end
  end
end

# USER STATE FUNCTIONS

define :save_state do |filename|
  _state.save_state filename
end

define :load_state do |filename|
  _state.load_state filename
end

# STATE

defonce :_state do
  SonicJam::State.new
end

define :set_state do |ns, state|
  if _ns_ok(ns)
    _state.set_state state
    send_state_json("*", ns)
  end
end

define :drop_state do |ns|
  if _ns_ok(ns)
    _state.drop_state ns
    send_state_json("*", ns)
  end
end

define :get_state_json do |ns|
  return JSON.dump(_state.get_state(ns))
end

define :send_state_json do |client_id, ns|
  jam_client.send("/state", JSON.dump([client_id, ns, get_state_json(ns)]))
end

define :_ns_ok do |ns|
  if not ns or not ns.is_a? Symbol
    puts "ns #{ns} is not a symbol"
    return false
  end
  return true
end

# SERVER

defonce :jam_server do
  SonicPi::OSC::UDPServer.new(4559, use_decoder_cache: true)
end

defonce :jam_client do
  SonicPi::OSC::UDPClient.new("127.0.0.1", 4560, use_encoder_cache: true)
end

jam_server.add_method("/drop-state") do |args|
  assert(args.length == 2)
  client_id = args[0]
  ns = args[1].intern
  drop_state ns
end

jam_server.add_method("/set-state") do |args|
  assert(args.length == 3)
  client_id = args[0]
  ns = args[1].to_sym
  state = JSON.parse(args[2], symbolize_names: true)
  set_state ns, state
end

jam_server.add_method("/get-state") do |args|
  assert(args.length == 2)
  client_id = args[0]
  ns = args[1].to_sym
  send_state_json(client_id, ns)
end

jam_server.add_method("/get-samples") do |args|
  assert(args.length == 1)
  client_id = args[0]
  a = all_sample_names
  done = false
  while not done
    b = a.take(10)
    jam_client.send("/samples", JSON.dump([client_id, JSON.dump(Array.new(b))]))
    a = a.drop(10)
    if a.count == 0
      done = true
    end
  end
end

jam_server.add_method("/get-synths") do |args|
  assert(args.length == 1)
  client_id = args[0]
  a = synth_names
  done = false
  while not done
    b = a.take(10)
    jam_client.send("/synths", JSON.dump([client_id, JSON.dump(Array.new(b))]))
    a = a.drop(10)
    if a.count == 0
      done = true
    end
  end
end

jam_server.add_method("/ping") do |args|
  assert(args.length == 1)
  client_id = args[0]
  jam_client.send("/pong", JSON.dump([client_id]))
end