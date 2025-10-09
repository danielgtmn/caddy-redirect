.PHONY: test build clean help

# Default target
help:
	@echo "Available commands:"
	@echo "  make test      - Run all tests"
	@echo "  make build     - Build Docker image"
	@echo "  make clean     - Clean up containers and images"
	@echo "  make test-ci   - Run tests for CI environment"
	@echo "  make help      - Show this help"

# Run all tests
test: build
	@echo "Running tests..."
	@./test.sh

# Build Docker image
build:
	@echo "Building Docker image..."
	docker build -t caddy-redirect:test .

# Clean up
clean:
	@echo "Cleaning up..."
	docker stop caddy-test caddy-custom-test backend-test 2>/dev/null || true
	docker rm caddy-test caddy-custom-test backend-test 2>/dev/null || true
	docker rmi caddy-redirect:test 2>/dev/null || true
	docker system prune -f

# CI test (without interactive parts)
test-ci: build
	@echo "Running CI tests..."
	@./test.sh

# Quick validation (syntax only)
validate:
	@echo "Validating configuration..."
	docker run --rm -v $(PWD):/config caddy:2-alpine caddy validate --config /config/Caddyfile
