# TikzPictures

This library allows one to create Tikz pictures and save in various formats. It integrates with IJulia, outputting SVG images to the notebook.

In order to use this library, lualatex must be installed. The texlive and miktex distributions include lualatex. You must also have dvisvgm installed. On Ubuntu, you can get these, if not already present, by running `sudo apt-get install texlive-latex-base` and `sudo apt-get install texlive-binaries`.

## Example
```julia
using TikzPictures
tp = TikzPicture("\\draw (0,0) -- (10,10);\n\\draw (10,0) -- (0,10);\n\\node at (5,5) {tikz};", options="scale=0.25", preamble="")
save(PDF("test"), tp)
save(SVG("test"), tp)
save(TEX("test"), tp)
```
