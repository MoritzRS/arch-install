.PHONY: build deploy

build:
	@rm installer.zip
	@zip -r installer.zip installer

deploy:
	@python -m http.server