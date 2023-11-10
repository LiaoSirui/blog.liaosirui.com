push:
	git add -A
	git config --local user.name "Liao Sirui"
	git config --local user.email "cyril@liaosirui.com"
	git commit -m 'update site at $(shell date +%Y%m%d-%H%M%S), machine $(shell hostname)'
	git pull --rebase
	git push --set-upstream origin HEAD
