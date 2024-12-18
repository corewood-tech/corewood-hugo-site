## Conventions reference: https://web.mit.edu/gnu/doc/html/make_14.html
SHELL = /bin/sh

# All site assets will be in the `/src` directory
site_dir = src

all:
	@echo "> Compiling static site"

install: start_podman_machine
	@echo "> Checking for dependencies and configure"

clean:
	@echo "> Removing stuff"

dist:
	@echo "> Compiling site for distribution"

run:
	@echo "> Running Hugo server"
	podman run -p 1313:1313 -v "$(PWD)/$(site_dir):/src" corewood-hugo-site server --forceSyncStatic --buildDrafts

.PHONY: new_site
new_site: build_image
	@echo "> Creating a new site scaffold in $(site_dir). This will overwrite any existing site data, including content."
	@read -p ">> Are you sure? [y/N] " ans && ans=$${ans:-N} ; \
		if [ $${ans} = y ] || [ $${ans} = Y ]; then \
			podman run -v "$(PWD)/$(site_dir):/home/site" corewood-hugo-site new site /home/site --force; \
		else \
			echo ">> Operation cancelled"; \
		fi

.PHONY: add_theme
add_theme: theme_repo = https://github.com/sbruder/spectral
add_theme:
	@echo ">> Adding submodule for $(theme_repo)"
	git submodule add "$(theme_repo)" "$(site_dir)/themes/installed"

.PHONY: install_yq
install_yq: formula = yq
install_yq: brew_formula_install

.PHONY: install_podman
install_podman: formula = podman
install_podman: brew_formula_install

.PHONY: brew_formula_install
brew_formula_install:
	@echo "> Checking if $(formula) is installed"
	@if ! command -v "$(formula)" &> /dev/null; then \
		echo ">> $(formula) not found; installing..."; \
		brew install "$(formula)"; \
	else \
		echo ">> $(formula) installed"; \
	fi

.PHONY: build_image
build_image: start_podman_machine
	podman build -t corewood-hugo-site .

.PHONY: start_podman_machine
start_podman_machine: init_podman_machine
	@echo "> Checking if podman machine is started"
	@if [ "`podman machine info --format json | yq '.Host.MachineState'`" != "Running" ]; then \
		echo ">> Starting podman machine"; \
		podman machine start default-machine; \
	else \
		echo ">> Podman machine is running"; \
	fi


.PHONY: init_podman_machine
init_podman_machine: install_podman
	@echo "> Checking if podman is initialized"
	@if [ "`podman machine info --format json | yq '.Host.MachineState'`" = "" ]; then \
		echo ">> No podman machine running. Initializing..."; \
		podman machine init default-machine; \
	else \
		echo "Podman machine is initialized"; \
	fi