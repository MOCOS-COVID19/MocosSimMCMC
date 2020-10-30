mutable struct MoveProposer
  steps::Vector{Pair{Symbol, Function}}
  i::UInt
end
MoveProposer(steps) = MoveProposer(steps, 1)

function sample(rng::AbstractRNG, sampler::MoveProposer, fp::FitParams)
  sym, fun = sampler.steps[sampler.i]
  sampler.i += 1
  if sampler.i > length(sampler.steps)
    sampler.i = 1
  end
  lens = Setfield.PropertyLens{sym}()
  old = get(fp, lens)
  set(fp, lens, old+fun(rng))
end

lastmoveparam(sampler::MoveProposer) = sampler.steps[sampler.i][1]
