# name: Agnoster
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for FISH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).

## Set this options in your config.fish (if you want to :])
# set -g theme_display_user yes
# set -g theme_hide_hostname yes
# set -g theme_hide_hostname no
# set -g default_user your_normal_user

set -g current_bg NONE
set segment_separator \uE0B0
set right_segment_separator \uE0B0
set -g KFK_VERSIONING ''
# ===========================
# Helper methods
# ===========================

set -g __fish_git_prompt_showdirtystate 'yes'
set -g __fish_git_prompt_char_dirtystate '±'
set -g __fish_git_prompt_char_cleanstate ''
set -g __fish_git_prompt_char_addedstate '•'
function parse_git_dirty
  set -l submodule_syntax
  set submodule_syntax "--ignore-submodules=dirty"
  set git_dirty (command git status --porcelain $submodule_syntax  2> /dev/null)
  command git status --porcelain $submodule_syntax  2> /dev/null | command grep -e "^?? " -e "^ M " 2>/dev/null >/dev/null
  set git_added $status
  if [ -n "$git_dirty" ]
    if [ $__fish_git_prompt_showdirtystate = "yes" ]
      if [ $git_added = 1 ]
        echo -n "$__fish_git_prompt_char_addedstate"
      else
        echo -n "$__fish_git_prompt_char_dirtystate"
      end
    end
  else
    if [ $__fish_git_prompt_showdirtystate = "yes" ]
      echo -n "$__fish_git_prompt_char_cleanstate"
    end
  end
end


# ===========================
# Segments functions
# ===========================

function prompt_segment -d "Function to draw a segment"
  set -l bg
  set -l fg
  if [ -n "$argv[1]" ]
    set bg $argv[1]
  else
    set bg normal
  end
  if [ -n "$argv[2]" ]
    set fg $argv[2]
  else
    set fg normal
  end
  if [ "$current_bg" != 'NONE' -a "$argv[1]" != "$current_bg" ]
    set_color -b $bg
    set_color $current_bg
    echo -n "$segment_separator "
    set_color -b $bg
    set_color $fg
  else
    set_color -b $bg
    set_color $fg
    echo -n " "
  end
  set current_bg $argv[1]
  if [ -n "$argv[3]" ]
    echo -n -s $argv[3] " "
  end
end

function prompt_finish -d "Close open segments"
  if [ -n $current_bg ]
    set_color -b normal
    set_color $current_bg
    if [ $KFK_VERSIONING = '_' ]
      echo -n " "
    else
      echo -n "$segment_separator "
    end
  end
  set -g current_bg NONE
end


# ===========================
# Theme components
# ===========================

function prompt_virtual_env -d "Display Python virtual environment"
  if test "$VIRTUAL_ENV"
    prompt_segment white black
    echo -n (basename $VIRTUAL_ENV)
  end
end

function prompt_user -d "Display current user if different from $default_user"
  if [ "$theme_display_user" = "yes" ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      get_hostname
      if [ $HOSTNAME_PROMPT ]
        set USER_PROMPT $USER@$HOSTNAME_PROMPT
      else
        set USER_PROMPT $USER
      end
      if [ "$USER" = "root" ]
        prompt_segment black red $USER_PROMPT
      else
        prompt_segment white black $USER_PROMPT
      end
    end
  end
end

function get_hostname -d "Set current hostname to prompt variable $HOSTNAME_PROMPT if connected via SSH"
  set -g HOSTNAME_PROMPT ""
  if [ "$theme_hide_hostname" = "no" -o \( "$theme_hide_hostname" != "yes" -a -n "$SSH_CLIENT" \) ]
    set -g HOSTNAME_PROMPT (hostname | cut -d"." -f1)
  end
end

function prompt_dir -d "Display the current directory"
  prompt_segment blue black
  echo -n (prompt_pwd)
end


function prompt_hg -d "Display mercurial state"
  set -l branch
  set -l state
  if command hg id >/dev/null 2>&1
    if command hg prompt >/dev/null 2>&1
      set branch (command hg prompt "{branch}")
      set state (command hg prompt "{status}")
      set branch_symbol \uE0A0
      if [ "$state" = "!" ]
        prompt_segment red white
        echo "$branch_symbol $branch ±"
        set -g KFK_VERSIONING '_'
      else if [ "$state" = "?" ]
          prompt_segment yellow black
          echo "$branch_symbol $branch ±"
          set -g KFK_VERSIONING '_'
      else
          prompt_segment green black
          echo "$branch_symbol $branch"
          set -g KFK_VERSIONING '_'
      end
    end
  end
end


function prompt_git -d "Display the current git state"
  set -l ref
  set -l dirty
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
    set dirty (parse_git_dirty)
    set ref (command git symbolic-ref HEAD 2> /dev/null)
    if [ $status -gt 0 ]
      set -l branch (command git show-ref --head -s --abbrev |head -n1 2> /dev/null)
      set ref "➦ $branch "
    end
    set branch_symbol \uE0A0
    set -l branch (echo $ref | sed  "s-refs/heads/-$branch_symbol -")
    if [ "$KFK_NOBRANCH" = "" ]
      if [ "$dirty" != "" ]
        prompt_segment black yellow
        echo -n "$branch $dirty"
        set -g KFK_VERSIONING '_'
      else
        prompt_segment black green
        echo -n "$branch"
        set -g KFK_VERSIONING '_'
      end
    else
      if [ "$dirty" != "" ]
        prompt_segment black yellow
        echo -n $branch_symbol
      else
        prompt_segment black green
        echo -n $branch_symbol
      end
    end
  end
end


function prompt_svn -d "Display the current svn state"
  set -l ref
  if command svn ls . >/dev/null 2>&1
    set branch (svn_get_branch)
    set branch_symbol \uE0A0
    set revision (svn_get_revision)
    prompt_segment green black "$branch_symbol $branch:$revision"
    set -g KFK_VERSIONING '_'
  end
end

function svn_get_branch -d "get the current branch name"
  svn info 2> /dev/null | awk -F/ \
      '/^URL:/ { \
        for (i=0; i<=NF; i++) { \
          if ($i == "branches" || $i == "tags" ) { \
            print $(i+1); \
            break;\
          }; \
          if ($i == "trunk") { print $i; break; } \
        } \
      }'
end

function svn_get_revision -d "get the current revision number"
  svn info 2> /dev/null | sed -n 's/Revision:\ //p'
end


function prompt_status -d "the symbols for a non zero exit status, root and background jobs"
    if [ $RETVAL -ne 0 ]
      prompt_segment black red "✘"
    end

    # if superuser (uid == 0)
    set -l uid (id -u $USER)
    if [ $uid -eq 0 ]
      #prompt_segment black yellow "⚡"
    end

    # Jobs display
    if [ (jobs -l | wc -l) -gt 0 ]
      prompt_segment black cyan "⚙"
    end
end

# ===========================
# Apply theme
# ===========================

function fish_long_prompt
  set -g KFK_VERSIONING ''
  set -g RETVAL $status
  prompt_status
  prompt_virtual_env
  prompt_user
  prompt_dir
  type -q hg;  and prompt_hg
  type -q git; and prompt_git
  type -q svn; and prompt_svn
  prompt_finish
end

function fish_short_prompt
  set -l fish_prompt_pwd_dir_length_save $fish_prompt_pwd_dir_length
  set -g fish_prompt_pwd_dir_length 1
  set -g KFK_VERSIONING ''
  set -g RETVAL $status
  prompt_status
  prompt_virtual_env
  prompt_user
  prompt_dir
  set -g KFK_NOBRANCH _
  type -q hg;  and prompt_hg
  type -q git; and prompt_git
  type -q svn; and prompt_svn
  prompt_finish
  set -e KFK_NOBRANCH
  set -g fish_prompt_pwd_dir_length $fish_prompt_pwd_dir_length_save
end


function fish_prompt
  set -l long_prompt_output (fish_long_prompt)
  if [ (string length (string trim (echo -n $long_prompt_output | perl -pe 's/\x1b\[[0-9;]*[mG]//g' ))) -ge $COLUMNS ]
    fish_short_prompt
  else
    echo -n $long_prompt_output
  end
end









