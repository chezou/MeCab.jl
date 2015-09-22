# MeCab.jl

[![Build Status](https://travis-ci.org/chezou/MeCab.jl.svg?branch=master)](https://travis-ci.org/chezou/MeCab.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaStats/MeCab.jl/badge.svg)](https://coveralls.io/r/JuliaStats/MeCab.jl)
[![MeCab](http://pkg.julialang.org/badges/MeCab_0.3.svg)](http://pkg.julialang.org/?pkg=MeCab&ver=0.3)
[![MeCab](http://pkg.julialang.org/badges/MeCab_0.4.svg)](http://pkg.julialang.org/?pkg=MeCab&ver=0.4)

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

If you don't install mecab and libmecab yet, MeCab.jl will install mecab, libmecab and mecab-ipadic under unix-like environment.

## Credits
MeCab.jl is created by Michiaki Ariga

[MeCab](http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html) by Taku Kudo
