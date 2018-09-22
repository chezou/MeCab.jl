module MeCab
using Libdl

# Load dependencies
deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("MeCab not properly installed. Please run Pkg.build(\"MeCab\")")
end

@assert @isdefined libmecab

import Base: parse
export Mecab, MecabNode, sparse_tostr, nbest_sparse_tostr, mecab_sparse_tonode,
       nbest_init, nbest_next_tostr, parse_tonode, parse_surface, parse_surface2, parse_nbest

mutable struct Mecab
  ptr::Ptr{Nothing}

  function Mecab(option::String = "")
    argv = vcat("mecab", split(option))
    ptr = ccall(
      (:mecab_new, libmecab),
      Ptr{Nothing},
      (Cint, Ptr{Ptr{UInt8}}),
      length(argv), argv
    )

    if ptr == C_NULL
      error("failed to create tagger")
    end
    smart_p = new(ptr)

    finalizer(obj -> ccall((:mecab_destroy, libmecab),  Nothing, (Ptr{Nothing},), obj.ptr), smart_p)

    smart_p
  end
end

mutable struct MecabRawNode
  prev::Ptr{MecabRawNode}
  next::Ptr{MecabRawNode}
  enext::Ptr{MecabRawNode}
  bnext::Ptr{MecabRawNode}
  rpath::Ptr{Nothing}
  lpath::Ptr{Nothing}
  surface::Ptr{UInt8}
  feature::Ptr{UInt8}
  id::Cint
  length::Cushort
  rlength::Cushort
  rcAttr::Cushort
  lcAttr::Cushort
  posid::Cushort
  char_type::Cuchar
  stat::Cuchar
  isbest::Cuchar
  alpha::Cfloat
  beta::Cfloat
  prob::Cfloat
  wcost::Cshort
  cost::Clong
end

mutable struct MecabNode
  surface::String
  feature::String
end

function create_node(raw::MecabRawNode)
  MecabNode(
    create_surface(raw),
    unsafe_string(raw.feature),
  )
end

function create_surface(raw::MecabRawNode)
  local surface::String
  surface = try
     unsafe_string(raw.surface, raw.length)
  catch
     unsafe_string(raw.surface)
  end
end

function create_nodes(raw::Ptr{MecabRawNode})
  ret = Array{MecabNode}(undef, 0)
  while raw != C_NULL
    _raw = unsafe_load(raw)
    if _raw.length != 0
      push!(ret, create_node(_raw))
    end
    raw = _raw.next
  end
  ret
end

function create_surfaces(raw::Ptr{MecabRawNode})
  ret = Array(String, 0)
  while raw != C_NULL
    _raw = unsafe_load(raw)
    if _raw.length != 0
      push!(ret, create_surface(_raw))
    end
    raw = _raw.next
  end
  ret
end

function sparse_tostr(mecab::Mecab, input::AbstractString)
  result = ccall(
      (:mecab_sparse_tostr, libmecab), Ptr{UInt8},
      (Ptr{UInt8}, Ptr{UInt8},),
      mecab.ptr, string(input)
    )
  local ret::String
  ret = chomp(unsafe_string(result))
  ret
end

function nbest_sparse_tostr(mecab::Mecab, n::Int64, input::AbstractString)
  result = ccall(
      (:mecab_nbest_sparse_tostr, libmecab), Ptr{UInt8},
      (Ptr{UInt8}, Int32, Ptr{UInt8},),
      mecab.ptr, n, string(input)
    )
  local ret::String
  ret = chomp(unsafe_string(result))
  ret
end

function mecab_sparse_tonode(mecab::Mecab, input::AbstractString)
  node = ccall(
      (:mecab_sparse_tonode, libmecab), Ptr{MecabRawNode},
      (Ptr{UInt8}, Ptr{UInt8},),
      mecab.ptr, string(input)
    )
  node
end

function nbest_init(mecab::Mecab, input::AbstractString)
  ccall((:mecab_nbest_init, libmecab), Nothing, (Ptr{Nothing}, Ptr{UInt8}), mecab.ptr, string(input))
end

function nbest_next_tostr(mecab::Mecab)
  result = ccall((:mecab_nbest_next_tostr,libmecab), Ptr{UInt8}, (Ptr{Nothing},), mecab.ptr)
  local ret::String
  ret = chomp(unsafe_string(result))
  ret
end

function parse(mecab::Mecab, input::String)
  node = mecab_sparse_tonode(mecab, input)
  local ret::Array{MecabNode}
  ret = create_nodes(node)
end

function parse_surface(mecab::Mecab, input::String)
  results = [ split(line, "\t")[1] for line = split(sparse_tostr(mecab, input), "\n") ]
  # If you don't need EOS, you can remove following
  if isempty(results)
    return []
  end
  pop!(results)
  results
end

function parse_surface2(mecab::Mecab, input::String)
  node = mecab_sparse_tonode(mecab, input)
  local ret::Array{String}
  ret = create_surfaces(node)
end

function parse_nbest(mecab::Mecab, n::Int64, input::String)
  results = split(nbest_sparse_tostr(mecab, n, input), "EOS\n")

  filter(x -> !isempty(x), [create_mecab_results(convert(Array{String}, split(result,"\n"))) for result in results])
end

function create_mecab_results(results::Array{String, 1})
  filter(x -> x != nothing, map(mecab_result, results))
end

function mecab_result(input::String)
  if isempty(input) || input == "EOS"
    return
  end
  surface, feature = split(input)
  MecabNode(surface, feature)
end
end
