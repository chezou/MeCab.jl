module MeCab

export Mecab, MecabResult, sparse_tostr, nbest_sparse_tostr, nbest_init, nbest_next_tostr, parse_tonode, parse, parse_surface

type Mecab
  ptr::Ptr{Void}

  function Mecab(option::String = "")
    argv = split(option)
    if(length(argv) == 0)
      argv = [""]
    end

    ptr = ccall(
      (:mecab_new, "libmecab"),
      Ptr{Void},
      (Cint, Ptr{Ptr{Uint8}}),
      length(argv), argv
    )

    if ptr == C_NULL
      error("failed to create tagger")
    end
    smart_p = new(ptr)

    finalizer(smart_p, obj -> ccall((:mecab_destroy, "libmecab"),  Void, (Ptr{Void},), obj.ptr))

    smart_p
  end
end

type MecabResult
  surface::String
  feature::String
end

function sparse_tostr(mecab::Mecab, input::String)
  result = ccall(
      (:mecab_sparse_tostr, "libmecab"), Ptr{Uint8},
      (Ptr{Uint8}, Ptr{Uint8},),
      mecab.ptr, bytestring(input)
    )
  bytestring(result)
end

function nbest_sparse_tostr(mecab::Mecab, n::Int64, input::String)
  result = ccall(
      (:mecab_nbest_sparse_tostr, "libmecab"), Ptr{Uint8},
      (Ptr{Uint8}, Int32, Ptr{Uint8},),
      mecab.ptr, n, bytestring(input)
    )
  bytestring(result)
end

function nbest_init(mecab::Mecab, input::String)
  ccall((:mecab_nbest_init, "libmecab"), Void, (Ptr{Void}, Ptr{Uint8}), mecab.ptr, bytestring(input))
end

function nbest_next_tostr(mecab::Mecab)
  result = ccall((:mecab_nbest_next_tostr,"libmecab"), Ptr{Uint8}, (Ptr{Void},), mecab.ptr)
  bytestring(result)
end

function parse(mecab::Mecab, input::String)
  results = split(sparse_tostr(mecab, input), "\n")
  pop!(results)
  pop!(results)
  nodes = MecabResult[]
  for result in results
    surface, feature = split(result)
    push!(nodes, MecabResult(surface, feature))
  end

  nodes
end

function parse_surface(mecab::Mecab, input::String)
  results = parse(mecab, input)
  map((x) -> x.surface, results)
end

end
