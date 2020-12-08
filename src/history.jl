import Base.push!

Base.@kwdef struct HistoryRecord
  seed::UInt
  accepted::Bool
  fitparams::FitParams
  moveparam::Symbol

  trajectory::Vector{UInt64} = UInt32[]
  offset::Int = 0

  ll_prior::Float64 = NaN
  ll_traj::Float64 = NaN
  ll_joint::Float64 = NaN

  ll_acc::Float64 = NaN
  ll_thresh::Float64 = NaN
end

function history2df(history::AbstractVector{HistoryRecord})
  df = DataFrame()
  for fieldname in filter(e->e∉[:trajectory, :fitparams], fieldnames(HistoryRecord))
    column = getproperty.(history, fieldname)
    df[:, fieldname] = column
  end
  fp = getproperty.(history, :fitparams)

  for (i,fieldname) in enumerate(fieldnames(FitParams))
    column = getproperty.(fp, fieldname)
    pos = 3 + i
    insertcols!(df, pos, fieldname => column)
  end
  df[:, :trajectory] = getproperty.(history, :trajectory)
  df
end
