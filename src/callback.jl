struct Callback
  max_total_detections::UInt
  max_daily_detections::UInt
end

Callback(;max_num_detected::Integer=10^8, max_daily_detected=10^8) = Callback(max_num_detected, max_daily_detected)

function reset!(::Callback)
end

function (cb::Callback)(event::MocosSim.Event, state::MocosSim.SimState, ::MocosSim.SimParams)
  eventkind = MocosSim.kind(event)
  if ! MocosSim.isdetection(eventkind)
      return true
  end

  today_detected = MocosSim.dailydetections(state.stats)[end]
  total_detected = MocosSim.numdetected(state.stats)

  return total_detected < cb.max_total_detections && today_detected < cb.max_daily_detections
end