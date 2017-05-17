# TikzPictures

[![Build Status](https://travis-ci.org/sisl/TikzPictures.jl.svg)](https://travis-ci.org/sisl/TikzPictures.jl)
[![Coverage Status](https://coveralls.io/repos/github/sisl/TikzPictures.jl/badge.svg?branch=master)](https://coveralls.io/github/sisl/TikzPictures.jl?branch=master)



This library allows one to create Tikz pictures and save in various formats. It integrates with IJulia, outputting SVG images to the notebook.

In order to use this library, lualatex must be installed. The texlive and miktex distributions include lualatex. You must also have dvisvgm installed. On Ubuntu, you can get these, if not already present, by running `sudo apt-get install texlive-latex-base` and `sudo apt-get install texlive-binaries`.

You also need pdf2svg. On Ubuntu, you can get this by running `sudo apt-get install pdf2svg`. On Windows, you can download the binaries from http://www.cityinthesky.co.uk/opensource/pdf2svg/. Be sure to add pdf2svg to your path (and restart).

Note: this package will attempt to turn off interpolation in the generated SVG, but this currently only works in Chrome.

## Example

```julia
using TikzPictures
tp = TikzPicture("\\draw (0,0) -- (10,10);\n\\draw (10,0) -- (0,10);\n\\node at (5,5) {tikz \$\\sqrt{\\pi}\$};", options="scale=0.25", preamble="")
save(PDF("test"), tp)
save(SVG("test"), tp)
save(TEX("test"), tp)
save(TIKZ("test"), tp)
```

As you can see above, you have to escape backslashes and dollar signs in LaTeX. To simplify things, this package provides the LaTeXString type, which can be constructed via L"...." without escaping backslashes or dollar signs.

```julia
tp = TikzPicture(L"""
\draw (0,0) -- (10,10);
\draw (10,0) -- (0,10);
\node at (5,5) {tikz $\sqrt{\pi}$};"""
, options="scale=0.25", preamble="")
```
