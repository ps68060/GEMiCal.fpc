# Compiler and flags
FPC = fpc
UNIT_PATHS = -Fu./src -Fu./tests/unit
BUILD_DIR = ./build
UNIT_OUT = $(BUILD_DIR)/units

# Test runner program
TEST_RUNNER = tests/runners/runtests.pas
TEST_BINARY = $(BUILD_DIR)/runtests

# Default target
all: $(TEST_BINARY)

# Build the test runner
$(TEST_BINARY): $(TEST_RUNNER)
    mkdir -p $(BUILD_DIR)
    mkdir -p $(UNIT_OUT)
    $(FPC) $(UNIT_PATHS) -FE$(BUILD_DIR) -FU$(UNIT_OUT) $(TEST_RUNNER)

# Run tests
test: $(TEST_BINARY)
    $(TEST_BINARY)

# Clean build artifacts
clean:
    rm -rf $(BUILD_DIR)
