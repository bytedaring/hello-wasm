/*
req = new XMLHttpRequest();
req.open('GET', 'mandelbrot.wasm');
req.responseType = 'arraybuffer';
req.send()

var cnv = window.document.getElementById("canvas");
var ctx = cnv.getContext("2d");

var wasm_loaded = false;
get_pixel_color = (x, y) => 0;

var main = function() {
  for (let i = 0; i < cnv.width; i++) {
    for (let j = 0; j < cnv.height; j++) {
      var iters = get_pixel_color(i, j);
      ctx.fillStyle = "rgb(" + iters + ", " + iters + ", " + iters + ")";
      ctx.fillRect(i, j, 1, 1);
    }
  }
}

req.onload = function() {
  var bytes = req.response;
  WebAssembly.instantiate(bytes, {
    env: {
      print: (rst) => { console.log(`The result is ${rst}`); }
    }
  }).then(rst => {
    get_pixel_color = rst.instance.exports.get_pixel_color;
    wasm_loaded = true;

    main();
  })
}
*/

// References to Exported Zig function 
let Game;

// Export JavaScript Functions to Zig
const importObject = {
  env: {
    print: (x) => { console.log(x); }
  }
}

var canvas = window.document.getElementById("canvas");
var ctx = canvas.getContext("2d");

var wasm_loaded = false;

var main = function() {
  for (let i = 0; i < canvas.width; i++) {
    for (let j = 0; j < canvas.height; j++) {
      var iters = Game.instance.exports.get_pixel_color(i, j);
      ctx.fillStyle = "rgb(" + iters + ", " + iters + ", " + iters + ")";
      ctx.fillRect(i, j, 1, 1);
    }
  }
}

async function bootstrap() {
  // https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/instantiateStreaming
  Game = await WebAssembly.instantiateStreaming(
    fetch("mandelbrot.wasm"),
    importObject
  );
  main();
}

// Start the loading of WebAssembly Module
bootstrap();
