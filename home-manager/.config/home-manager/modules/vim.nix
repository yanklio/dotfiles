{ config, lib, pkgs, ... }:

{
  programs.vim = {
    enable = true;
    
    extraConfig = ''
      source $VIMRUNTIME/defaults.vim

      if has('vms')
        set nobackup
      else
        set backup
        if has('persistent_undo')
          set undofile
        endif
      endif

      if &t_Co > 2 || has("gui_running")
        set hlsearch
      endif


      augroup vimrcEx
        au!

        autocmd FileType text setlocal textwidth=78
      augroup END

      if has('syntax') && has('eval')
        packadd! matchit
      endif

      set number
      syntax on
    '';
  };
}
