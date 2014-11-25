module MeCab

# Load dependencies
deps = joinpath(Pkg.dir("MeCab"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("MeCab not properly installed. Please run Pkg.build(\"MeCab\")")
end

@assert isdefined(:libmecab)

export Mecab, MecabNode, sparse_tostr, nbest_sparse_tostr, mecab_sparse_tonode,
       nbest_init, nbest_next_tostr, parse_tonode, parse, parse_surface, parse_surface2, parse_nbest

type Mecab
  ptr::Ptr{Void}

  function Mecab(option::ASCIIString = "")
    argv = vcat("mecab", split(option))

    ptr = ccall(
      (:mecab_new, libmecab),
      Ptr{Void},
      (Cint, Ptr{Ptr{Uint8}}),
      length(argv), argv
    )

    if ptr == C_NULL
      error("failed to create tagger")
    end
    smart_p = new(ptr)

    finalizer(smart_p, obj -> ccall((:mecab_destroy, libmecab),  Void, (Ptr{Void},), obj.ptr))

    smart_p
  end
end

type MecabRawNode
  prev::Ptr{MecabRawNode}
  next::Ptr{MecabRawNode}
  enext::Ptr{MecabRawNode}
  bnext::Ptr{MecabRawNode}
  rpath::Ptr{Void}
  lpath::Ptr{Void}
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

type MecabNode
  surface::UTF8String
  feature::UTF8String
end

function create_node(raw::MecabRawNode)
  MecabNode(
    create_surface(raw),
    bytestring(raw.feature),
  )
end

function create_surface(raw::MecabRawNode)
  _surface = bytestring(raw.surface)
  surface::UTF8String
  surface = try
      _surface[1:raw.length]
    catch
      _surface[1:1]
    end
end

function create_nodes(raw::Ptr{MecabRawNode})
  ret = Array(MecabNode, 0)
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
  ret = Array(UTF8String, 0)
  while raw != C_NULL
    _raw = unsafe_load(raw)
    if _raw.length != 0
      push!(ret, create_surface(_raw))
    end
    raw = _raw.next
  end
  ret
end

function sparse_tostr(mecab::Mecab, input::String)
  result = ccall(
      (:mecab_sparse_tostr, libmecab), Ptr{Uint8},
      (Ptr{UInt8}, Ptr{UInt8},),
      mecab.ptr, bytestring(input)
    )
  ret::UTF8String
  ret = chomp(bytestring(result))
  ret
end

function nbest_sparse_tostr(mecab::Mecab, n::Int64, input::String)
  result = ccall(
      (:mecab_nbest_sparse_tostr, libmecab), Ptr{UInt8},
      (Ptr{UInt8}, Int32, Ptr{UInt8},),
      mecab.ptr, n, bytestring(input)
    )
  ret::UTF8String
  ret = chomp(bytestring(result))
  ret
end

function mecab_sparse_tonode(mecab::Mecab, input::String)
  node = ccall(
      (:mecab_sparse_tonode, libmecab), Ptr{MecabRawNode},
      (Ptr{UInt8}, Ptr{UInt8},),
      mecab.ptr, bytestring(input)
    )
  node
end

function nbest_init(mecab::Mecab, input::String)
  ccall((:mecab_nbest_init, libmecab), Void, (Ptr{Void}, Ptr{Uint8}), mecab.ptr, bytestring(input))
end

function nbest_next_tostr(mecab::Mecab)
  result = ccall((:mecab_nbest_next_tostr,libmecab), Ptr{Uint8}, (Ptr{Void},), mecab.ptr)
  ret::UTF8String
  ret = chomp(bytestring(result))
  ret
end

function parse(mecab::Mecab, input::UTF8String)
  node = mecab_sparse_tonode(mecab, input)
  ret::Array{MecabNode}
  ret = create_nodes(node)
end

function parse(mecab::Mecab, input::ASCIIString)
  if isempty(input)
    return []
  end
  parse(mecab, utf8(input))
end

function parse_surface(mecab::Mecab, input::UTF8String)
  results = [ split(line, "\t")[1] for line = split(sparse_tostr(mecab, input), "\n") ]
  # If you don't need EOS, you can remove following
  if isempty(results)
    return []
  end
  pop!(results)
  results
end

function parse_surface(mecab::Mecab, input::ASCIIString)
  parse_surface(mecab, utf8(input))
end

function parse_surface2(mecab::Mecab, input::UTF8String)
  node = mecab_sparse_tonode(mecab, input)
  ret::Array{UTF8String}
  ret = create_surfaces(node)
end

function parse_nbest(mecab::Mecab, n::Int64, input::UTF8String)
  results = split(nbest_sparse_tostr(mecab, n, input), "EOS\n")

  filter(x -> !isempty(x), [create_mecab_results(convert(Array{UTF8String}, split(result,"\n"))) for result in results])
end

function parse_nbest(mecab::Mecab, n::Int64, input::ASCIIString)
  parse_nbest(mecab, n, utf8(input))
end

function create_mecab_results(results::Array{UTF8String, 1})
  filter(x -> x != nothing, map(mecab_result, results))
end

function mecab_result(input::UTF8String)
  if isempty(input) || input == "EOS"
    return
  end
  surface, feature = split(input)
  MecabNode(surface, feature)
end
end
