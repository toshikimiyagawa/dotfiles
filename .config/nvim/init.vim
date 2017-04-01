cd /
if has('mac')
	set fencs=cp932,iso-2022-jp,euc-jp,utf-16le,utf-16,latin1
endif
if has('win32')
	set fencs=utf-8,iso-2022-jp,euc-jp,utf-16le,utf-16,latin1
endif

set number
set noswapfile

augroup MyAutoCmd
  autocmd!
augroup END

let g:python3_host_prog = expand('/usr/bin/python3')
let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
	if !isdirectory(s:dein_repo_dir)
		execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
	endif
	execute 'set runtimepath^=' . s:dein_repo_dir
endif

if dein#load_state(s:dein_dir)
	call dein#begin(s:dein_dir)

	let g:rc_dir    = expand('~/.config/dein')
	let s:toml      = g:rc_dir . '/dein.toml'
	let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

	call dein#load_toml(s:toml,      {'lazy': 0})
	call dein#load_toml(s:lazy_toml, {'lazy': 1})

	call dein#end()
	call dein#save_state()
endif

if dein#check_install()
	call dein#install()
endif

call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')

let g:quickrun_config = {
			\	"_" : {
			\		"outputter/buffer/split" : ":botright",
			\		"outputter/buffer/close_on_empty" : 1
			\	},
			\	"cpp" : {
			\		'command': 'clang++',
			\		'cmdopt': '-std=c++14 -I /usr/include/boost'
			\	}
			\}

filetype plugin indent on

noremap <C-c> <ESC>
noremap <C-g> <ESC>

inoremap <C-M-F2>; <Nop>
inoremap <C-M-F2>: <Nop>
nnoremap <silent> <C-M-F2>; :call OtherWindowOrSplit()<cr>
nnoremap <silent> <C-M-F2>: :Denite buffer file_mru file_rec<cr>
nnoremap <silent> <C-\>; :call OtherWindowOrSplit()<cr>
nnoremap <silent> <C-\>: :Denite buffer file_mru file_rec<cr>
noremap <Insert> <Nop>
inoremap <Insert> <Nop>

syntax on
set t_Co=256
set guioptions=e
set cursorline

function! OtherWindowOrSplit()
	if winnr("$") > 1
		:wincmd w
	else
		:vsplit
	endif
endfunction

