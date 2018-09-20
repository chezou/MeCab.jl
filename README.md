# MeCab.jl

[![Build Status](https://travis-ci.org/chezou/MeCab.jl.svg?branch=master)](https://travis-ci.org/chezou/MeCab.jl)
[![Coverage Status](https://coveralls.io/repos/chezou/MeCab.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/chezou/MeCab.jl?branch=master)

Julia bindings for Japanese morphological analyzer [MeCab](http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html)

## Usage

```julia
using MeCab

# Create MeCab tagger
mecab = Mecab()

# You can give MeCab option like "-o wakati"
# mecab = Mecab("-o wakati")

# Parse text
# It returns Array of MecabNode type
results = parse(mecab, "すももももももももものうち")

# Access each result.
# It returns Array of String
for result in results
  println(result.surface, ":", result.feature)
end

# Parse surface
results = parse_surface(mecab, "すももももももももものうち")

# Access each result
# It returns Array of Array of MecabNode
for result in results
  println(result)
end

# Parse nbest result
nbest_results = parse_nbest(mecab, 3, "すももももももももものうち")
for nbest_result in nbest_results
  for result in nbest_result
    println(result.surface, ":", result.feature)
  end
  println()
end

```

## Requirement
- mecab
- dictionary for mecab (such as mecab-ipadic, mecab-naist-jdic, and so on)

If you don't install mecab and libmecab yet, MeCab.jl will install mecab, libmecab and mecab-ipadic that are confirmed to work with MeCab.jl under unix-like environment.

Note that by default, MeCab.jl will try to find system-installed libmecab (e.g. /usr/lib/libmecab.dylib). If you have already libmecab installed, this might cause library or dictionary incompatibility that MeCab.jl assumes. If you have any problem with system-installed ones, please try to ignore them and rebuild MeCab.jl by:

```jl
julia> ENV["MECABJL_LIBRARY_IGNORE_PATH"] = "/usr/lib:/usr/local/lib" # depends on your environment
julia> Pkg.build("MeCab")
```

The libmecab library path will be stored in `MeCab.libmecab` after loading MeCab.jl. The library path should look like for example:

```jl
julia> using MeCab
julia> MeCab.libmecab
"$your_home_dir_path/.julia/v0.4/MeCab/deps/usr/lib/libmecab.dylib"
```

## Credits
MeCab.jl is created by Michiaki Ariga

Original [MeCab](http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html) is created by Taku Kudo

### Contributors
- [r9y9](https://github.com/r9y9)
- [snthot](https://github.com/snthot)
- [tkelman](https://github.com/tkelman)
