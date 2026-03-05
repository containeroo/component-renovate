# The component name is hard-coded from the template
COMPONENT_NAME ?= renovate

git_dir         ?= $(shell git rev-parse --git-common-dir)
compiled_path   ?= compiled/$(COMPONENT_NAME)/$(COMPONENT_NAME)
root_volume     ?= -v "$${PWD}:/$(COMPONENT_NAME)"
compiled_volume ?= -v "$${PWD}/$(compiled_path):/$(COMPONENT_NAME)"
component_alias ?= $(if $(filter defaults,$(instance)),,$(instance))
commodore_args  ?= --search-paths . -n $(COMPONENT_NAME) $(if $(component_alias),-a $(component_alias),)

ifneq "$(git_dir)" ".git"
	git_volume        ?= -v "$(git_dir):$(git_dir):ro"
	antora_git_volume ?= -v "$(git_dir):/preview/antora/.git:ro"
else
	git_volume        ?=
	antora_git_volume ?= -v "${PWD}/.git:/preview/antora/.git:ro"
endif

ifneq "$(shell which docker 2>/dev/null)" ""
	DOCKER_CMD    ?= $(shell which docker)
	DOCKER_USERNS ?= ""
else ifneq "$(shell which podman 2>/dev/null)" ""
	DOCKER_CMD    ?= $(shell which podman)
	DOCKER_USERNS ?= keep-id
else
	DOCKER_CMD    ?=
	DOCKER_USERNS ?=
endif
DOCKER_ARGS ?= run --rm -u "$$(id -u):$$(id -g)" --userns=$(DOCKER_USERNS) -w /$(COMPONENT_NAME) -e HOME="/$(COMPONENT_NAME)"
DOCKER_EXTRA_ARGS ?=

CA_CERT_FILE ?=
CA_CERT_PATH ?= /tmp/custom-ca.pem
CA_CERT_FILE_RESOLVED ?= $(if $(filter ~/%,$(CA_CERT_FILE)),$(HOME)/$(patsubst ~/%,%,$(CA_CERT_FILE)),$(CA_CERT_FILE))
ifneq ($(strip $(CA_CERT_FILE)),)
	ca_cert_volume ?= -v "$(abspath $(CA_CERT_FILE_RESOLVED)):$(CA_CERT_PATH):ro"
	ca_cert_env    ?= -e SSL_CERT_FILE="$(CA_CERT_PATH)" -e REQUESTS_CA_BUNDLE="$(CA_CERT_PATH)" -e CURL_CA_BUNDLE="$(CA_CERT_PATH)"
else
	ca_cert_volume ?=
	ca_cert_env    ?=
endif

JSONNET_FILES   ?= $(shell find . -type f -not -path './vendor/*' \( -name '*.*jsonnet' -or -name '*.libsonnet' \))
JSONNETFMT_ARGS ?= --in-place --pad-arrays
JSONNET_IMAGE   ?= ghcr.io/projectsyn/jsonnet:latest
JSONNET_DOCKER  ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) --entrypoint=jsonnetfmt $(JSONNET_IMAGE)

YAMLLINT_ARGS   ?= --no-warnings
YAMLLINT_CONFIG ?= .yamllint.yml
YAMLLINT_IMAGE  ?= docker.io/cytopia/yamllint:latest
YAMLLINT_DOCKER ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) $(YAMLLINT_IMAGE)

VALE_CMD  ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) --volume "$${PWD}"/docs/modules:/pages ghcr.io/vshn/vale:2.15.5
VALE_ARGS ?= --minAlertLevel=error --config=/pages/ROOT/pages/.vale.ini /pages

ANTORA_PREVIEW_CMD ?= $(DOCKER_CMD) run --rm --publish 35729:35729 --publish 2020:2020 $(antora_git_volume) --volume "${PWD}/docs":/preview/antora/docs ghcr.io/vshn/antora-preview:3.1.2.3 --style=syn --antora=docs

COMPILE_CMD    ?= $(COMMODORE_CMD) component compile . $(commodore_args)
ifneq ($(strip $(DOCKER_CMD)),)
	COMMODORE_CMD ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(DOCKER_EXTRA_ARGS) $(ca_cert_env) $(git_volume) $(root_volume) $(ca_cert_volume) docker.io/projectsyn/commodore:latest
	JB_CMD        ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(DOCKER_EXTRA_ARGS) $(ca_cert_env) $(root_volume) $(ca_cert_volume) --entrypoint /usr/local/bin/jb docker.io/projectsyn/commodore:latest install
else
	COMMODORE_CMD ?= commodore
	JB_CMD        ?= jb install
endif
GOLDEN_FILES    ?= $(shell find tests/golden/$(instance) -type f)

KUBENT_FILES    ?= $(shell echo "$(GOLDEN_FILES)" | sed 's/ /,/g')
KUBENT_ARGS     ?= -c=false --helm3=false -e
KUBENT_IMAGE    ?= ghcr.io/doitintl/kube-no-trouble:latest
KUBENT_DOCKER   ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) --entrypoint=/app/kubent $(KUBENT_IMAGE)

instance ?= defaults
test_instances = tests/defaults.yml tests/tenant-a.yml tests/valkey.yml
