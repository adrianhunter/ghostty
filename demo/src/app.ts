import type { ModuleConfig } from "./emscripten.ts";
import Ghostty from "./lib/ghostty.js";

const Module: ModuleConfig = {
  preRun: [],
  print: function(o) {
    o = Array.prototype.slice.call(arguments).join(" "), console.log(o);
  },
  printErr: function(o) {
    o = Array.prototype.slice.call(arguments).join(" "), console.error(o);
  },
};
window.onerror = function() {
  //   console.log("onerror: " + event.message);
};

export async function start() {
  const ghostty = await Ghostty(Module);

  console.log("Ghostty initialized", ghostty);

  const defaultFN = ghostty.default;

  console.log("Default function:", defaultFN);
  // if (ghostty == null) {
  //     throw new Error("Failed to initialize Ghostty");
  // }

  // // @ts-ignore
  // window.ghostty = ghostty;

  // // @ts-ignore
  // return ghostty;
}
