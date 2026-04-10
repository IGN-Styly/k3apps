SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

ARTIFACTS_DIR ?= .artifacts
MAKEPKG_CONF ?= repo/config/makepkg.conf

.PHONY: build validate srcinfo subtree-update list-packages site-dev site-build site-build-pages site-check

list-packages:
	find packages -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

build:
	@if [[ -z "$${PKG:-}" ]]; then echo "PKG=<pkgbase> is required"; exit 1; fi
	./repo/scripts/build_changed.sh --verify-srcinfo --output-dir "$(ARTIFACTS_DIR)/packages" "$$PKG"

validate:
	@if [[ -z "$${PKG:-}" ]]; then echo "PKG=<pkgbase> is required"; exit 1; fi
	./repo/scripts/build_changed.sh --verify-srcinfo --lint --output-dir "$(ARTIFACTS_DIR)/packages" "$$PKG"

srcinfo:
	@if [[ -z "$${PKG:-}" ]]; then echo "PKG=<pkgbase> is required"; exit 1; fi
	cd "packages/$$PKG" && makepkg --printsrcinfo > .SRCINFO

subtree-update:
	@if [[ -z "$${PKG:-}" ]]; then echo "PKG=<pkgbase> is required"; exit 1; fi
	source "packages/$$PKG/source.conf" && git subtree pull --prefix "$$UPSTREAM_PREFIX" "$$UPSTREAM_URL" "$$UPSTREAM_REF" --squash

site-dev:
	cd site && pnpm dev

site-build:
	cd site && pnpm build

site-build-pages:
	cd site && pnpm build:pages

site-check:
	cd site && pnpm check
