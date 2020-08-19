using TikzPictures
using Test

svgBackends = [
    "testPic.pdf2svg.svg" => PdfToSvgBackend(),
    "testPic.poppler.svg" => PopplerBackend(),
    "testPic.dvisvgm.svg" => DVIBackend()
]

# Pre-test cleanup (for repeated tests)
for file in ["testPic.pdf", "testPic.svg", "testDoc.pdf", "testDoc.tex", first.(svgBackends)...]
	if isfile(file)
		rm(file)
	end
end

# Run tests
data = "\\draw (0,0) -- (10,10);\n\\draw (10,0) -- (0,10);\n\\node at (5,5) {tikz \$\\sqrt{\\pi}\$};"
tp = TikzPicture(data, options="scale=0.25", preamble="")
td = TikzDocument()
push!(td, tp, caption="hello")

save(TEX("testPic"), tp)
@test isfile("testPic.tex")

# check that the TEX file contains the desired environments
function has_environment(content::String, environment::String)
    has_begin = occursin("\\begin{$environment}", content)
    has_end = occursin("\\end{$environment}", content)
    if has_begin && has_end
        return true # has both
    elseif !has_begin && !has_end
        return false # has neither
    else
        error("\\begin{$environment} and \\end{$environment} do not match")
    end
end
filecontent = join(readlines("testPic.tex", keep=true)) # read with line breaks
@test occursin(data, filecontent) # also check that the data is contained
@test has_environment(filecontent, "tikzpicture")
@test has_environment(filecontent, "document")

# same check for include_preamble=false and limit_to=:picture
save(TEX("testPic"; include_preamble=false), tp)
filecontent = join(readlines("testPic.tex", keep=true))
@test occursin(data, filecontent)
@test has_environment(filecontent, "tikzpicture") # must occur
@test !has_environment(filecontent, "document") # must not occur

# same check for limit_to=:data
save(TEX("testPic"; limit_to=:data), tp)
filecontent = join(readlines("testPic.tex", keep=true))
@test occursin(data, filecontent)
@test !has_environment(filecontent, "tikzpicture")
@test !has_environment(filecontent, "document")

save(TEX("testPic"), tp) # save again with limit_to=:all
if success(`lualatex -v`)
	save(PDF("testPic"), tp)
	@test isfile("testPic.pdf")

    save(SVG("testPic"), tp)
    @test isfile("testPic.svg") # default SVG backend

    @testset for (k, v) in svgBackends
        svgBackend(v)
        save(SVG(k), tp)
        @test isfile(k)
    end

    save(PDF("testDoc"), td)
    @test isfile("testDoc.pdf")
else
    @warn "lualatex is missing; can not test compilation"
end
