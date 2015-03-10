
function! game_engine#xxd#read(path, ...) abort
  let xs = []
  if filereadable(a:path)
    let offset = 0 < a:0 ? (0 < str2nr(a:1) ? str2nr(a:1) : 0) : 0
    let length = 1 < a:0 ? str2nr(a:2) : getfsize(a:path)
    if 0 <= length && length < 4 * 1024 * 1024
      let lines = split(system(printf('xxd -s %d -l %d -g 1 "%s"', offset, length, a:path)), "\n")
      for line in lines
        let xs += split(matchlist(line, '^[0-9a-f]\+: \(\%([0-9a-f]\{2,2} \)*\).*$')[1], ' ')
      endfor
    else
      throw printf('game_engine#xxd#read: Reading bytes should be less than 4MB. (%d bytes) ', length)
    endif
  endif
  return map(xs, 'eval("0x" . v:val)')
endfunction

function! game_engine#xxd#write(xs, path) abort
  let t = tempname()
  let lines = []
  let line = ''
  for i in range(1, len(a:xs))
    let line .= printf(' %02x', a:xs[i - 1])
    if 0 == i % 16 || i == len(a:xs)
      let lines += [printf('%07x:%s ', ((i + 15) / 16 - 1) * 16, line)]
      let line = ''
    endif
  endfor
  call writefile(lines, t)
  if filereadable(a:path)
    call delete(a:path)
  endif
  call system(printf('xxd -g 1 -r "%s" "%s"', t, a:path))
  if filereadable(t)
    call delete(t)
  endif
endfunction

