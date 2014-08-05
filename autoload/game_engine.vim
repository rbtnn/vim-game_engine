
scriptencoding utf-8

" let s:V = vital#of('vital')
let s:V = vital#of('game_engine.vim')
let s:List = s:V.import('Data.List')
let s:Random = s:V.import('Random.Xor128')
call s:Random.srand()

function! game_engine#version()
  return '0.0'
endfunction
function! game_engine#auto_funcref()
  try
    call b:session._.auto_funcref()
    call feedkeys(mode() is# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
  catch '.*'
  endtry
endfunction
function! game_engine#start_game(game_title, auto_funcref)
  tabnew
  call game_engine#buffer#uniq_open(a:game_title, [], "w")
  execute printf("%dwincmd w", game_engine#buffer#winnr(a:game_title))
  setlocal filetype=game_engine
  only

  let b:session = s:get_session(a:game_title, a:auto_funcref)

  if b:session._.windows_p
    setlocal guifont=Consolas:h2:cSHIFTJIS
  elseif b:session._.mac_p
    setlocal guifont=Menlo\ Regular:h5
  elseif b:session._.unix_p
    setlocal guifont=Monospace\ 2
  else
  endif

  augroup GameEngine
    autocmd!
    autocmd CursorHold,CursorHoldI * call game_engine#auto_funcref()
  augroup END

  if has('gui_running')
    let &columns = 9999
    let &lines = 999
  endif
endfunction
function! game_engine#exit_game()
  if &filetype is# "game_engine"
    augroup GameEngine
      autocmd!
    augroup END

    let &maxfuncdepth = b:session._.backup.maxfuncdepth
    let &guifont = b:session._.backup.guifont
    let &updatetime = b:session._.backup.updatetime
    let &titlestring = b:session._.backup.titlestring
    let &spell = b:session._.backup.spell
    let &list = b:session._.backup.list
    if has('gui_running')
      let &columns = b:session._.backup.columns
      let &lines = b:session._.backup.lines
    endif
    bdelete!
  endif
endfunction
function! game_engine#rand(n)
  return abs(s:Random.rand()) % a:n
endfunction
function! game_engine#scale2d(data, scale_dict, default)
  let lines = []
  for row in a:data
    let scaled_row = map(deepcopy(row),
          \ 's:List.zip(get(a:scale_dict, v:val, a:default))')
    for lnum in range(0, len(scaled_row[0]) - 1)
      let line = []
      for idx in range(0, len(scaled_row) - 1)
        let line += scaled_row[idx][lnum][0]
      endfor
      let lines += [line]
    endfor
  endfor
  return lines
endfunction

function! s:get_session(game_title, auto_funcref)
  let session = {}
  let session._ = {}

  let session._.V = s:V
  let session._.Random = s:Random
  let session._.List = s:List

  let session._.unix_p = s:is_unix()
  let session._.windows_p = s:is_windows()
  let session._.cygwin_p = s:is_cygwin()
  let session._.mac_p = s:is_mac()

  let session._.backup = {
        \   'guifont' : &guifont,
        \   'spell' : &spell,
        \   'updatetime' : &updatetime,
        \   'maxfuncdepth' : &maxfuncdepth,
        \   'titlestring' : &titlestring,
        \   'columns' : &columns,
        \   'lines' : &lines,
        \   'list' : &list,
        \ }

  let session._.game_title = a:game_title
  let session._.auto_funcref = a:auto_funcref

  function! session.redraw(lines) dict
    call game_engine#buffer#uniq_open(self._.game_title, a:lines, "w")
  endfunction

  return session
endfunction

function! s:is_unix()
  return has('unix') && ! has('mac')
endfunction
function! s:is_windows()
  return has('win95') || has('win16') || has('win32') || has('win64')
endfunction
function! s:is_cygwin()
  return has('win32unix')
endfunction
function! s:is_mac()
  return ! s:is_windows()
        \ && ! s:is_cygwin()
        \ && (
        \       has('mac')
        \    || has('macunix')
        \    || has('gui_macvim')
        \    || (  ! executable('xdg-open')
        \       && system('uname') =~? '^darwin'
        \       )
        \    )
endfunction

