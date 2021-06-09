# TikzPictures

[![Build Status](https://github.com/JuliaTeX/TikzPictures.jl/workflows/CI/badge.svg)](https://github.com/JuliaTeX/PGFPlots.jl/actions)
[![codecov](https://codecov.io/gh/JuliaTeX/TikzPictures.jl/branch/master/graph/badge.svg?token=nCBJc77iDE)](https://codecov.io/gh/JuliaTeX/TikzPictures.jl)

This library allows one to create Tikz pictures and save in various formats. It integrates with IJulia, outputting SVG images to the notebook.

In order to use this library, lualatex must be installed. The texlive and miktex distributions include lualatex. You must also have dvisvgm installed. On Ubuntu, you can get these, if not already present, by running `sudo apt-get install texlive-latex-base` and `sudo apt-get install texlive-binaries`.

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

## Embedding TEX files in external documents

Compiling a standalone LaTeX file requires the Tikz code to be wrapped in a `tikzpicture` environment, which again is wrapped in a `document` environment. You can omit these wrappers if you intend to embed the output in a larger document, instead of compiling it as a standalone file.

```julia
save(TEX("test"; limit_to=:all), tp) # the default, save a complete file
save(TEX("test"; limit_to=:picture), tp) # only wrap in a tikzpicture environment
save(TEX("test"; limit_to=:data), tp) # do not wrap the Tikz code, at all
```
