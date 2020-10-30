
function running_average!(tgt::AbstractArray{Tt} where Tt<:Number, arr::AbstractArray{Ts} where Ts<:Number, n::Integer)
  @assert n <= length(arr)
  @assert length(tgt) == length(arr) - n + 1

  T = promote_type(eltype(tgt), eltype(arr))
  s = T(0)
  for i in 1:n
    s += arr[i]
  end

  i = 1

  while true
    if T <: Rational
      tgt[i] = s // n
    else
      tgt[i] = s / n
    end
    if i >= length(tgt)
      break
    end
    s += T(arr[i+n]) - T(arr[i])
    i += 1
  end
  tgt
end

running_average(arr::AbstractArray{Ts} where Ts<:Number, n::Integer) =
  running_average!(Vector{Float64}(undef, length(arr)-n+1), arr, n)

abstract type TrajectoryError end

function loglikelihood(fitdist::TrajectoryError, trajectory::AbstractVector{T} where T<:Real)
  @assert length(trajectory) >= 29
  imax = 0
  llmax = -Inf

  for i in 29:length(trajectory)
    ll = (
      +loglikelihood(dist(fitdist, Val( 0)), round(trajectory[i   ]))
      +loglikelihood(dist(fitdist, Val( 7)), round(trajectory[i- 7]))
      +loglikelihood(dist(fitdist, Val(14)), round(trajectory[i-14]))
      +loglikelihood(dist(fitdist, Val(21)), round(trajectory[i-21]))
      +loglikelihood(dist(fitdist, Val(28)), round(trajectory[i-28]))
    )

    if ll > llmax
      imax = i
      llmax = ll
    end
  end
  imax, llmax
end

include("trajectory_errors/poissonerror.jl")
include("trajectory_errors/normalerror.jl")