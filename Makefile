SWIFT := swift
APP_NAME := ClipboardManager
APP_BUNDLE := .build/$(APP_NAME).app
INSTALL_DIR := /Applications
BUNDLE_ID := com.mreidt.clipboard-manager
CODESIGN_IDENTITY ?= -
DEVELOPMENT_DATA_DIR := $(CURDIR)/.build/development-data

.PHONY: build test release bundle install

build:
	$(SWIFT) build

test:
	$(SWIFT) build
	$(SWIFT) test
	CLIPBOARD_MANAGER_DATA_DIRECTORY="$(DEVELOPMENT_DATA_DIR)" $(SWIFT) run $(APP_NAME)

release:
	$(SWIFT) build -c release
	$$( $(SWIFT) build -c release --show-bin-path )/$(APP_NAME)

bundle:
	$(SWIFT) build -c release
	bin_path=$$($(SWIFT) build -c release --show-bin-path); \
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"; \
	cp "$$bin_path/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"; \
	cp "ClipboardManager/App/Info.plist" "$(APP_BUNDLE)/Contents/Info.plist"; \
	codesign --force --deep --sign "$(CODESIGN_IDENTITY)" --identifier "$(BUNDLE_ID)" "$(APP_BUNDLE)"; \
	if [ "$(CODESIGN_IDENTITY)" = "-" ]; then \
		echo "warning: ad-hoc signing requires Accessibility permission again after binary changes"; \
	fi

install: bundle
	-killall "$(APP_NAME)" 2>/dev/null; \
	mkdir -p "$(INSTALL_DIR)"; \
	ditto "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"; \
	open "$(INSTALL_DIR)/$(APP_NAME).app"
