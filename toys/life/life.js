var set_cell = null;
var advance = null;
var get_char = null;

var running = false;

var pre = document.getElementById("life_pre");
var reset = document.getElementById("button");

var Game = null;

var main = function(advancer) {
  console.log("Main started");
  var loop = function() {
    let string = "";
    pre.textContent = string;
    for (var i = 0; i < 1024; i++) {
      if ((i % 32) == 0) {
        string += "\n";
      }
      string += String.fromCharCode(get_char(i))
    }
    pre.textContent = string;
    // console.log(string);
    var num_changed = advancer();
    if (num_changed == 0)
      running = false
    if (running)
      window.requestAnimationFrame(loop);
  };
  loop();
}

const importObject = {
  env: {
    print: (result) => { console.log(`The result is ${result}`) }
  },
};

async function bootstrap() {
  Game = await WebAssembly.instantiateStreaming(
    fetch("life.wasm"), importObject
  )
  set_cell = Game.instance.exports.set_cell;
  advance = Game.instance.exports.advance;
  get_char = Game.instance.exports.get_char;
  wasm_loaed = true

  // bind an event to the reset button
  reset.onclick = function() {
    console.log("Reset clicked");
    for (let i = 0; i < 500; i++) {
      let randid = Math.random() * 1024;
      set_cell(randid);
    };
    running = true;
    main(advance);
  };

  // run code post wasm
  main(advance);
}

bootstrap()
