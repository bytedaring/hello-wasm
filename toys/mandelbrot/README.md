## Mandelbrot Toy

Mandelbrot Toy is a sample demo of generating a Mandelbrot fractal on an HTML5 Canvas using WebAssembly.

## compile wasm
```bash
$ zig build-lib mandelbrot.zig -target wasm32-freestanding -dynamic -O ReleaseSmall
```
