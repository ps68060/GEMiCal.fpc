# Compiler and flags
FPC = fpc
UNIT_PATHS = -Fu./src
BUILD_DIR = ./build
UNIT_OUT = $(BUILD_DIR)/units

# Main application entry point
MAIN = src/appmain.pas
APP_BINARY = $(BUILD_DIR)/app

# Default target
all: $(APP_BINARY)

# Build the main application
$(APP_BINARY): $(MAIN)
    mkdir -p $(BUILD_DIR)
    mkdir -p $(UNIT_OUT)
    $(FPC) $(UNIT_PATHS) -FE$(BUILD_DIR) -FU$(UNIT_OUT) $(MAIN)

# Run the application
run: $(APP_BINARY)
    $(APP_BINARY)

# Clean build artifacts
clean:
    rm -rf $(BUILD_DIR)
