push:
	git add -A
	git commit -m 'update site at $(shell date +%Y%m%d-%H%M%S)'
	git push --set-upstream origin HEAD

