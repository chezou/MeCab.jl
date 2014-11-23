module MeCab

# Load dependencies
deps = joinpath(Pkg.dir("MeCab"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("MeCab not properly installed. Please run Pkg.build(\"MeCab\")")
end

@assert isdefined(:libmecab)

export Mecab, MecabResult, sparse_tostr, nbest_sparse_tostr,
       nbest_init, nbest_next_tostr, parse_tonode, parse, parse_surface, parse_nbest

type Mecab
  ptr::Ptr{Void}

  function Mecab(option::String = "")
    argv = convert(Array{ASCIIString}, vcat("mecab", split(option)))

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

type MecabResult
  surface::UTF8String
  feature::UTF8String
end

function sparse_tostr(mecab::Mecab, input::String)
  result = ccall(
      (:mecab_sparse_tostr, libmecab), Ptr{Uint8},
      (Ptr{Uint8}, Ptr{Uint8},),
      mecab.ptr, bytestring(input)
    )
  chomp(bytestring(result))
end

function nbest_sparse_tostr(mecab::Mecab, n::Int64, input::String)
  result = ccall(
      (:mecab_nbest_sparse_tostr, libmecab), Ptr{Uint8},
      (Ptr{Uint8}, Int32, Ptr{Uint8},),
      mecab.ptr, n, bytestring(input)
    )
  chomp(bytestring(result))
end

function nbest_init(mecab::Mecab, input::String)
  ccall((:mecab_nbest_init, libmecab), Void, (Ptr{Void}, Ptr{Uint8}), mecab.ptr, bytestring(input))
end

function nbest_next_tostr(mecab::Mecab)
  result = ccall((:mecab_nbest_next_tostr,libmecab), Ptr{Uint8}, (Ptr{Void},), mecab.ptr)
  chomp(bytestring(result))
end

function parse(mecab::Mecab, input::String)
  results = split(sparse_tostr(mecab, input), "\n")

  create_mecab_results(convert(Array{UTF8String}, results))
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

function parse_nbest(mecab::Mecab, n::Int64, input::String)
  results = split(nbest_sparse_tostr(mecab, n, input), "EOS\n")

  filter(x -> !isempty(x), [create_mecab_results(convert(Array{UTF8String}, split(result,"\n"))) for result in results])
end

function create_mecab_results(results::Array{UTF8String, 1})
  filter(x -> x != nothing, map(mecab_result, results))
end

function mecab_result(input::String)
  if isempty(input) || input == "EOS"
    return
  end
  surface, feature = split(input)
  MecabResult(surface, feature)
end
end
