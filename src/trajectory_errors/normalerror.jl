struct NormalTrajectoryError <: TrajectoryError
  dists::NTuple{5, Normal{Float64}}
end

NormalTrajectoryError(data,
  relerr00::Real, relerr07::Real, relerr14::Real, relerr21::Real, relerr28::Real) = NormalTrajectoryError((
  Normal(data[end- 0], data[end- 0]*relerr00),
  Normal(data[end- 7], data[end- 7]*relerr07),
  Normal(data[end-14], data[end-14]*relerr14),
  Normal(data[end-21], data[end-21]*relerr21),
  Normal(data[end-28], data[end-28]*relerr28)
))

dist(err::NormalTrajectoryError, ::Val{I}) where I = err.dists[(I+7)/7]