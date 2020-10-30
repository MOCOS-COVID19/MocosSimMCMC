struct PoissonTrajectoryError <: TrajectoryError
  dists::NTuple{5, Poisson{Float64}}
end

PoissonTrajectoryError(data::AbstractVector{T} where T<: Real) = PoissonTrajectoryError((
  Poisson(data[end- 0]),
  Poisson(data[end- 7]),
  Poisson(data[end-14]),
  Poisson(data[end-21]),
  Poisson(data[end-28]),
))

dist(err::PoissonTrajectoryError, ::Val{I} where I) = err.dists[(I+7)/7]