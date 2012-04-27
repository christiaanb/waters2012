default: paper

paper:
	latexmk -r lhs2texmkrc -pdf -pvc waters2012.lhs

clean:
	latexmk -CA
