using TikzPictures
using Base.Test

using TikzPictures
tp = TikzPicture("\\draw (0,0) -- (10,10);\n\\draw (10,0) -- (0,10);\n\\node at (5,5) {tikz \$\\sqrt{\\pi}\$};", options="scale=0.25", preamble="")
save(TEX("test"), tp)
if success(`lualatex -v`)
    save(PDF("test"), tp)
    save(SVG("test"), tp)
end

tp = TikzPicture(L"""
\draw (0,0) -- (10,10);
\draw (10,0) -- (0,10);
\node at (5,5) {tikz $\sqrt{\pi}$};"""
, options="scale=0.25", preamble="")
save(TEX("test"), tp)
if success(`lualatex -v`)
    save(PDF("test"), tp)
    save(SVG("test"), tp)
end