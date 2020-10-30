struct FitParams
  c::Float64
  b::Float64
  q::Float64
  mloc::Int64
  msca::Int64
  mlim::Float64
end

function modified(simparams::MocosSim.SimParams, fp::FitParams)
  lens = @batchlens begin
  _.backward_tracing_prob
  _.forward_tracing_prob
  _.constant_kernel_param
  _.mild_detection_prob
  _.infection_modulation_function.loc
  _.infection_modulation_function.scale
  _.infection_modulation_function.limit_value
  end
  set(simparams, lens,
  (
    fp.b,
    fp.b,
    fp.c,
    fp.q,
    fp.mloc,
    fp.msca,
    fp.mlim
  )
)
end

struct FitPriors
  c::Distribution{Univariate, Continuous}
  b::Distribution{Univariate, Continuous}
  q::Distribution{Univariate, Continuous}
  mloc::Distribution{Univariate, Discrete}
  msca::Distribution{Univariate, Discrete}
  mlim::Distribution{Univariate, Continuous}
end

loglikelihood(priors::FitPriors, params::FitParams) = (
  + loglikelihood(priors.c, params.c)
  + loglikelihood(priors.b, params.b)
  + loglikelihood(priors.q, params.q)
  + loglikelihood(priors.mloc, params.mloc)
  + loglikelihood(priors.msca, params.msca)
  + loglikelihood(priors.mlim, params.mlim)
)