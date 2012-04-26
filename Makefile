default: paper

paper:
	latexmk -r latexmkrc -pdf -pvc waters2012.lhs

clean:
	latexmk -CA
