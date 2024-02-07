build:
	zig build

watch:
	find ./src -name '*.zig' | entr -rc zig build run

clean:
	rm -rf boast-out zig-cache zig-out
