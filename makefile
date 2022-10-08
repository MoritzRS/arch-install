.PHONY: build deploy

build:
	@zip -FSr installer.zip installer

deploy:
	@python -m http.server