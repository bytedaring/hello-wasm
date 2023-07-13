
var canvas = window.document.getElementById("game_canvas");
var ctx = canvas.getContext("2d");
ctx.font = "18px serif";

var Game = {
  'init': null,
  'get_pos': null,
  'set_pos': null,
  'update': null,
  'is_won': null,
};

var AppState = {
  'loaded': false,
  'running': false,
};

var rgb = function(r, g, b) {
  return "rgb(" + r + "," + g + "," + b + ")";
}

var main = function() {
  console.log("Main function started");

  var loop = function() {
    //clear the background
    ctx.fillStyle = "white";
    ctx.fillRect(0, 0, 100, 100)
    for (let x = 0; x < 10; x++) {
      for (let y = 0; y < 10; y++) {
        var cell = Game.get_pos(x, y);
        ctx.fillStyle = rgb(Game.red(cell), Game.green(cell), Game.black(cell));
        ctx.fillRect(x * 25, y * 25, (x * 25) + 25, (y * 25) + 25);
      }
    }

    if (Game.is_won()) {
      ctx.fillStyle = "18px red";
      ctx.fillText('You won!', 250, 250);
    }

    // loop to next frame
    if (AppState.running)
      window.requestAnimationFrame(loop);
  }
  loop();
}

window.document.body.onload = function() {
  var env = {
    env: (rst) => { console.log(rst); }
  }
  WebAssembly.instantiateStreaming(fetch("blockmaze.wasm"), env)
    .then(rst => {
      console.log("Loaded the WASM");
      Game = rst.instance.exports;
      AppState.loaded = true;
      AppState.running = true;
      Game.init();
      main();
    });
}

window.document.body.addEventListener('keydown', function(evt) {
  if (!AppState.loaded)
    return;
  if (evt.key == "w" || evt.key == "ArrowUp")
    Game.update(0);
  if (evt.key == "s" || evt.key == "ArrowDown")
    Game.update(1);
  if (evt.key == "a" || evt.key == "ArrowLeft")
    Game.update(2);
  if (evt.key == "d" || evt.key == "ArrowRight")
    Game.update(3);
  if (evt.key == "r")
    Game.init();
})
