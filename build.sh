
zig build \
  -Dtarget=wasm32-emscripten \
  -Dpie=true \
  -Dfont-backend=web_canvas \
  -freference-trace=100 \
  -Dapp-runtime=none \
  -Drenderer=opengl \
  -p demo/src/lib \
  --verbose


wasm-tools print demo/src/lib/ghostty.wasm -o demo/src/lib/ghostty.wat