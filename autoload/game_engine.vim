
scriptencoding utf-8

let s:V = vital#of('game_engine.vim')
let s:List = s:V.import('Data.List')
let s:Random = s:V.import('Random.Xor128')
let s:game_engine = {
      \  'save_data' : {},
      \ }
call s:Random.srand()

function! game_engine#version()
  if v:version < 704
    throw '[game_engine.vim] version 7.4 or higher is required to play a game.'
  endif
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

  if s:is_windows()
    setlocal guifont=Consolas:h2:cSHIFTJIS
  elseif s:is_mac()
    setlocal guifont=Menlo\ Regular:h5
  elseif s:is_unix()
    setlocal guifont=Monospace\ 2
  else
  endif
  let &l:spell = 0
  let &l:list = 0
  let &l:hlsearch = 0

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
function! game_engine#save_game(game_title, key)
  if &filetype is# "game_engine"
    if b:session._.game_title is a:game_title
      if !has_key(s:game_engine.save_data, a:game_title)
        let s:game_engine.save_data[(a:game_title)] = {}
      endif
      let s:game_engine.save_data[(a:game_title)][(a:key)] = deepcopy(b:session)
    endif
  endif
endfunction
function! game_engine#load_game(game_title, key)
  if &filetype is# "game_engine"
    if b:session._.game_title is a:game_title
      if !has_key(s:game_engine.save_data, a:game_title)
        let s:game_engine.save_data[(a:game_title)] = {}
      endif
      let b:session = deepcopy(get(s:game_engine.save_data[(a:game_title)], a:key, {}))
    endif
  endif
endfunction

function! game_engine#rand(n)
  return abs(s:Random.rand()) % a:n
endfunction

" echo game_engine#scale2d([
"       \[1,2],
"       \[3,4]],
"       \ {
"       \  '1' : [[1,1,1],
"       \         [1,1,1],
"       \         [1,1,1]],
"       \  '2' : [[4,4,4],
"       \         [4,4,4],
"       \         [4,4,4]],
"       \  '4' : [[16,16,16],
"       \         [16,16,16],
"       \         [16,16,16]],
"       \ }, [[0,0,0],
"       \     [0,0,0],
"       \     [0,0,0]])
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

function! game_engine#syntax(...)
  let syntax_dict = {}

  let syntax_dict['_ff0000'] = { 'gui' : '#ff0000', 'cterm' : 'Red' }
  let syntax_dict['_00ff00'] = { 'gui' : '#00ff00', 'cterm' : 'Green' }
  let syntax_dict['_0000ff'] = { 'gui' : '#0000ff', 'cterm' : 'Blue' }
  let syntax_dict['_ffff00'] = { 'gui' : '#ffff00', 'cterm' : 'Yellow' }
  let syntax_dict['_8B008B'] = { 'gui' : '#8B008B', 'cterm' : 'DarkMagenta' }
  let syntax_dict['_965042'] = { 'gui' : '#965042', 'cterm' : 'DarkRed' }
  let syntax_dict['_ffffff'] = { 'gui' : '#ffffff', 'cterm' : 'White' }
  let syntax_dict['_000000'] = { 'gui' : '#000000', 'cterm' : 'Black' }
  let syntax_dict['_333333'] = { 'gui' : '#333333', 'cterm' : 'Gray' }
  let syntax_dict['_ff00ff'] = { 'gui' : '#ff00ff', 'cterm' : 'Magenta' }
  for key in keys(deepcopy(syntax_dict))
    let syntax_dict[syntax_dict[key].cterm] = deepcopy(syntax_dict[key])
  endfor

  for arg_dict in a:000
    let key = tr(arg_dict.gui, '#', '_')
    if !has_key(syntax_dict, key)
      let syntax_dict[key] = arg_dict
    endif
  endfor

  let ts =
  \   map(range(0, 9), 'nr2char(0x30 + v:val)')
  \ + map(range(1, 26), 'nr2char(0x40 + v:val)')
  \ + map(range(1, 26), 'nr2char(0x60 + v:val)')
  let idx = 0
  for key in keys(syntax_dict)
    let syntax_dict[key].text = '@' . ts[idx]
    let idx += 1
  endfor

  return syntax_dict
endfunction
function! game_engine#define_syntax(name, dict)
  execute printf('highlight! game_engine%sHi guifg=%s guibg=%s ctermfg=%s ctermbg=%s',
        \   a:name,
        \   a:dict['gui'], a:dict['gui'],
        \   a:dict['cterm'], a:dict['cterm']
        \   )
  execute printf('syntax match game_engine%s  "%s"',
        \   a:name, a:dict['text'])
  execute printf('highlight! default link game_engine%s game_engine%sHi',
        \ a:name, a:name)
endfunction

function! s:get_session(game_title, auto_funcref)
  let session = {}
  let session._ = {}
  let session._.List = s:List

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
    redraw
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

