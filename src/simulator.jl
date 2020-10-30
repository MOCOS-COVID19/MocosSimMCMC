mutable struct Simulator
  simparams::MocosSim.SimParams
  simstate::MocosSim.SimState
  callback::Callback
end
Simulator(simparams::MocosSim.SimParams; max_total_detections::Integer, max_daily_detections) = Simulator(
  simparams,
  MocosSim.SimState(MocosSim.numindividuals(simparams)),
  Callback(max_total_detections, max_daily_detections)
)

function (self::Simulator)(fitparams::FitParams, seed::Integer, num_initial::Integer)
  self.simparams = modified(self.simparams, fitparams)
  MocosSim.reset!(self.simstate, seed)
  reset!(self.callback)
  MocosSim.initialfeed!(self.simstate, num_initial)
  MocosSim.simulate!(self.simstate, self.simparams, self.callback)
  MocosSim.dailydetections(self.simstate.stats)
end

#88borwziq