mutable struct Sampler
  rng::MersenneTwister
  simulator::Simulator
  numinitial::UInt

  fitpriors::FitPriors
  movesampler::MoveProposer
  trajectoryerror::TrajectoryError

  iterno::UInt
  accepted_fitparams::FitParams
  ll_last::Float64

  global_seed::UInt

  Sampler(;
    move_seed::Integer, simparams::MocosSim.SimParams, trajectory_error::TrajectoryError,
    moves::AbstractVector{Pair{Symbol, Function}}, fitpriors::FitPriors, initial_fitparams::FitParams,
    num_initial::Real=100, max_total_detections::Real=10^9, max_daily_detections::Real=10^9,
    global_seed::Integer=0) = new(

    MersenneTwister(move_seed),
    Simulator(simparams, max_total_detections=max_total_detections, max_daily_detections=max_daily_detections),
    num_initial,

    fitpriors,
    MoveProposer(moves),
    trajectory_error,

    0, initial_fitparams, -Inf,

    global_seed
  )
end



function nextsample!(s::Sampler)::HistoryRecord
  s.iterno += 1
  ll_acc = log(rand(s.rng, Float64))
  ll_thresh = s.ll_last + ll_acc

  proposed_fitparams = sample(s.rng, s.movesampler, s.accepted_fitparams)
  moveparam = lastmoveparam(s.movesampler)
  ll_prior = loglikelihood(s.fitpriors, proposed_fitparams)

  seed = s.iterno + s.global_seed
  if !(ll_prior > -Inf)
    return HistoryRecord(seed=seed, accepted=false, fitparams=proposed_fitparams, moveparam=moveparam)
  end

  trajectory = s.simulator(proposed_fitparams, seed, s.numinitial) |> copy
  offset, ll_traj = loglikelihood(s.trajectoryerror, running_average(trajectory, 7))
  ll_joint = ll_prior + ll_traj

  accepted = (ll_joint >= ll_thresh)

  if accepted
    s.accepted_fitparams = proposed_fitparams
    s.ll_last = ll_joint
  end

  return HistoryRecord(
    seed=seed, accepted=accepted, fitparams=proposed_fitparams, moveparam=moveparam,
    trajectory=trajectory, offset=offset,
    ll_prior=ll_prior, ll_traj=ll_traj, ll_joint=ll_joint,
    ll_acc=ll_acc, ll_thresh=ll_thresh)
end
