SWIFT := swift
APP_NAME := ClipboardManager
RELEASE_BINARY := .build/arm64-apple-macosx/release/$(APP_NAME)

.PHONY: build test release

build:
	$(SWIFT) build

test:
	$(SWIFT) build
	$(SWIFT) test
	$(SWIFT) run $(APP_NAME)

release:
	$(SWIFT) build -c release
	$(RELEASE_BINARY)
