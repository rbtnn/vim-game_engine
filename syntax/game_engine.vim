
if exists ("b:current_syntax")
  finish
endif

let s:dict = game_engine#syntax()
for s:name in keys(s:dict)
  call game_engine#define_syntax(s:name, s:dict[(s:name)])
endfor

let b:current_syntax = "game_engine"

