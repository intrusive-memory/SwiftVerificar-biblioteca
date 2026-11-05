# SwiftVerificarBiblioteca Makefile
#
# Every build and test goes through xcodebuild; SwiftPM's own drivers
# (`swift build` / `swift test`) are not used. Apple Silicon only (arm64).

SCHEME      = SwiftVerificarBiblioteca
DESTINATION = 'platform=macOS,arch=arm64'
ARCH        = ARCHS=arm64 ONLY_ACTIVE_ARCH=YES
XCODE_FLAGS = -skipPackagePluginValidation -skipMacroValidation

.PHONY: help resolve build test clean
.DEFAULT_GOAL := help

help:
	@echo "SwiftVerificarBiblioteca - available targets:"
	@echo "  help     - Show this help message (default)"
	@echo "  resolve  - Resolve package dependencies"
	@echo "  build    - Resolve, then build every target for macOS (arm64)"
	@echo "  test     - Run the test suite on macOS (arm64)"
	@echo "  clean    - Remove build artifacts"

resolve:
	xcodebuild -resolvePackageDependencies -scheme $(SCHEME) -destination $(DESTINATION)

build: resolve
	xcodebuild build -scheme $(SCHEME) -destination $(DESTINATION) $(XCODE_FLAGS) CODE_SIGNING_ALLOWED=NO $(ARCH)

test:
	xcodebuild test -scheme $(SCHEME) -destination $(DESTINATION) $(XCODE_FLAGS) CODE_SIGNING_ALLOWED=NO $(ARCH)

clean:
	xcodebuild clean -scheme $(SCHEME) -destination $(DESTINATION) $(ARCH)
	rm -rf .build
