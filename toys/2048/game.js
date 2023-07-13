
var canvas = window.document.getElementById("game_canvas");
var ctx = canvas.getContext("2d");
ctx.font = "18px serif";

var Game = {
  'init': null,
  'get_pos': null,
  'update': null,
  'is_won': null,
};

var AppState = {
  'loaded': false,
  'running': false,
};

const BK_GROUNND = {
  2: "#eee4da",
  4: "#ede0c8",
  8: "#f2b179",
  16: "#f59563",
  32: "#f67c5f",
  64: "#f65e3b",
  128: "#edcf72",
  256: "#edcc61",
  512: "#edc850",
  1024: "#edc53f",
  2048: "#edc22e",
  4096: "#eee4da",
  8192: "#edc22e",
  16384: "#f2b179",
  32768: "#f59563",
  65536: "#f67c5f",
}

const CELL_COLOR_DICT = {
  2: "#776e65",
  4: "#776e65",
  8: "#f9f6f2",
  16: "#f9f6f2",
  32: "#f9f6f2",
  64: "#f9f6f2",
  128: "#f9f6f2",
  256: "#f9f6f2",
  512: "#f9f6f2",
  1024: "#f9f6f2",
  2048: "#f9f6f2",
  4096: "#776e65",
  8192: "#f9f6f2",
  16384: "#776e65",
  32768: "#776e65",
  65536: "#f9f6f2",
}

const BACKGROUND_COLOR_GAME = "#92877d"
const BACKGROUND_COLOR_CELL_EMPTY = "#9e948a"
const GRID_LEN = 4;
const GRID_WIDTH = 70;
const GRID_PADDING = 4;

var main = function() {
  console.log("Main function started");

  var loop = function() {
    ctx.fillStyle = BACKGROUND_COLOR_GAME;
    ctx.fillRect(0, 0, GRID_LEN * GRID_WIDTH, GRID_WIDTH * GRID_LEN)
    for (let x = 0; x < GRID_LEN; x++) {
      for (let y = 0; y < GRID_LEN; y++) {
        var cell = Game.get_pos(x, y);
        ctx.fillStyle = cell == 0 ? BACKGROUND_COLOR_CELL_EMPTY : BK_GROUNND[cell];
        ctx.fillRect(x * GRID_WIDTH + GRID_PADDING, y * GRID_WIDTH + GRID_PADDING, GRID_WIDTH - GRID_PADDING * 2, GRID_WIDTH - GRID_PADDING * 2);
        if (cell != 0) {
          ctx.font = "16px serif blod";
          ctx.fillStyle = CELL_COLOR_DICT[cell];
          ctx.fillText(cell, x * GRID_WIDTH + GRID_WIDTH / 2, y * GRID_WIDTH + GRID_WIDTH / 2);
        }
      }
    }

    if (Game.is_won()) {
      ctx.fillStyle = "18px red";
      ctx.fillText('You won!', 100, 100);
      AppState.running = false;
    }

    // loop to next frame
    if (AppState.running)
      window.requestAnimationFrame(loop);
  }
  loop();
  // window.requestAnimationFrame(loop);
}

window.document.body.onload = function() {
  const importObj = {
    env: {
      print: (rst) => { console.log(rst); },
      rand: (max) => {
        return Math.floor(Math.random() * max);
      }
    }
  }
  WebAssembly.instantiateStreaming(fetch("2048.wasm"), importObj)
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
  if (evt.key == "w" || evt.key == "ArrowUp") {
    Game.update(0);
    main();
  }
  if (evt.key == "s" || evt.key == "ArrowDown") {
    Game.update(1);
    main();
  }
  if (evt.key == "a" || evt.key == "ArrowLeft") {
    Game.update(2);
    main();
  }
  if (evt.key == "d" || evt.key == "ArrowRight") {
    Game.update(3);
    main();
  }
  if (evt.key == "r") {
    Game.init();
    main();
  }
})
