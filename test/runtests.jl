using TikzPictures
using Test

# Pre-test cleanup (for repeated tests)
for file in ["testPic.pdf", "testPic.svg", "testDoc.pdf", "testDoc.tex"]
	if isfile(file)
		rm(file)
	end
end

# Run tests
tp = TikzPicture("\\draw (0,0) -- (10,10);\n\\draw (10,0) -- (0,10);\n\\node at (5,5) {tikz \$\\sqrt{\\pi}\$};", options="scale=0.25", preamble="")
td = TikzDocument()
push!(td, tp, caption="hello")
# save(TEX("testPic"), tp)
if success(`lualatex -v`)
	save(PDF("testPic"), tp)
    # save(SVG("testPic"), tp)
    # save(PDF("testDoc"), td)
end


