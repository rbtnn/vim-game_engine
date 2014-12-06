
function! s:start_game(f)
  try
    call game_engine#version()
    call function(a:f)()
  catch '.*'
    call game_engine#exit_game()
    echohl Error
    echomsg v:exception
    echomsg v:throwpoint
    echohl None
  endtry
endfunction
command! -nargs=1 GameEngineStartGame :call <sid>start_game(<q-args>)

