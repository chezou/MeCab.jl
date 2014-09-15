# MeCab.jl

[![Build Status](https://travis-ci.org/chezou/MeCab.jl.svg?branch=master)](https://travis-ci.org/chezou/MeCab.jl)

Julia bindings for Japanese morphological analyzer [MeCab](http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html)

## Usage

```julia
using MeCab

# Create MeCab tagger
# You can give MeCab option like "-o wakati"
mecab = Mecab()

# Parse text
# It returns Array of MecabResult type
results = parse(mecab, "すももももももももものうち")

# Access each result.
# It returns Array of String
for result in results
  println(result.surface, ":", result.feature)
end

# Parse surface
results = parse_surface(mecab, "すももももももももものうち")

# Access each result
# It returns Array of Array of MecabResult
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

## Requirement
- mecab
- dictionary for mecab (such as mecab-ipadic, mecab-naist-jdic, and so on)

## Credits
MeCab.jl is created by Michiaki Ariga

[MeCab](http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html) by Taku Kudo

```
