`boast` is a static git repo listing generator similar to [stagit][1], but
supports cloning out of the box via git's http "dumb" protocol.

Here's a live sample: <https://boast.imnhan.com/> ([repo here][2]) - it's still very barebones
at the moment, but cloning already works.

I'm still learning zig and manual memory management as I go, so please bear
with me.

# Deps

- Build: zig master (0.12-dev at the time of writing). Simply run `zig build`.
- Runtime: `git`

# Usage

```sh
boast <dir-that-contains-your-repos> <output-dir>
```

[1]: https://codemadness.org/stagit.html
[2]: https://github.com/nhanb/boast-demo
