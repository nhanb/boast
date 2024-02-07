build:
	zig build

watch:
	find ./src -name '*.zig' | entr -rc zig build run

serve:
	python -m http.server -b 127.0.0.1 -d ./boast-out

clean:
	rm -rf boast-out zig-cache zig-out
