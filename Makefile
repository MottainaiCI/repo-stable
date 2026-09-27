BACKEND?=dockerv3
CONCURRENCY?=1

# Abs path only. It gets copied in chroot in pre-seed stages
ANISE?=/usr/bin/anise-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd
CLEAN?=true
TREE?=./packages
BUILD_ARGS?=--image-repository macaroni-os/mottainairepo-amd64-cache --only-target-package
GENIDX_ARGS?=--only-upper-level --compress=false
CONFIG?= --config conf/anise.yaml
export ANISE_BIN?=$(ANISE)

.PHONY: all
all: build

.PHONY: clean
clean:
	rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(ANISE) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(ANISE) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)
	rm -rf $(ROOT_DIR)/build/*.image.tar

.PHONY: rebuild
rebuild:
	$(ANISE) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(ANISE) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: genidx
genidx:
	$(SUDO) $(ANISE) tree genidx $(GENIDX_ARGS) --tree=$(TREE)

.PHONY: create-repo
create-repo: genidx
	$(ANISE) create-repo $(CONFIG) --tree "$(TREE)" \
    --output $(ROOT_DIR)/build \
    --packages $(ROOT_DIR)/build \
    --name "mottainai-stable" \
    --descr "MottainaiCI Official Repository" \
    --urls "http://localhost:8000" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar.zst \
    --with-compilertree \
    --type http

.PHONY: serve-repo
serve-repo:
	ANISE_NOLOCK=true $(ANISE) serve-repo --port 8000 --dir $(ROOT_DIR)/build

.PHONY: autobump
autobump:
	TREE_DIR=$(ROOT_DIR) $(ANISE) autobump-github
	
.PHONY: auto-bump
auto-bump: autobump

.PHONY: validate
validate:
	$(ANISE) tree validate -t ${TREE}
