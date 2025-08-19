# Git
gmo() {
  git fetch origin
  git merge "origin/$1"
}
gro() {
  git fetch origin
  git rebase "origin/$1"
}
grio() {
  git fetch origin
  git rebase -i --update-refs "origin/$1"
}
alias gbl="git for-each-ref --sort='committerdate' --format='%(committerdate:short)%09%(refname:short)' refs/heads/"
dd-branch() {
  branchName="Ayc0/$(echo $1 | sed -e 's/Ayc0\///')"
  if [[ $(git rev-parse --verify -q "$branchName" || false) ]]
  then
    git switch "$branchName"
  else
    echo "Creating new branch '$branchName'"
    git switch -c "$branchName"
  fi
}
dd-done() {
  currentBranch=$(git branch --show-current)
  targetBranch="${1:-$currentBranch}"
  mainBranch=$(git symbolic-ref refs/remotes/origin/HEAD --short | sed -e 's@origin/@@')

  # Verify branch exists
  if [[ ! $(git rev-parse --verify -q "$targetBranch" || false) ]]
  then
    echo "$targetBranch doesn’t exist"
    return 1
  fi

  if [[ $targetBranch == $mainBranch ]]
  then
    echo "You can’t delete $targetBranch"
    return 1
  fi

  if [[ $currentBranch == $targetBranch ]]
  then
    git switch $mainBranch
    git branch -D $currentBranch
  else
    git branch -D $targetBranch
  fi

  git config --unset "branch.$targetBranch.remote"
  git config --unset "branch.$targetBranch.merge"
  git config --unset "branch.$targetBranch.vscode-merge-base"
  git config --unset "branch.$targetBranch.github-pr-owner-number"
  git config --unset "branch.$targetBranch.github-pr-base-branch"

  return 0
}
dd-clean-branches() {
  mainBranch=$(git symbolic-ref refs/remotes/origin/HEAD --short)
  for branch in $(git branch --merged $mainBranch | grep -vE '^[ *]*(prod|preprod)$');
  do
    git branch -d $branch
    git config --unset "branch.$branch.remote"
    git config --unset "branch.$branch.merge"
    git config --unset "branch.$branch.vscode-merge-base"
  done
  for branch in $(git branch | grep '\--fix-staging');
  do
    git branch -D $branch
    git config --unset "branch.$branch.remote"
    git config --unset "branch.$branch.merge"
    git config --unset "branch.$branch.vscode-merge-base"
  done
  for branch in $(git branch | grep -E 'staging-[0-9]+');
  do
    git branch -D $branch
    git config --unset "branch.$branch.remote"
    git config --unset "branch.$branch.merge"
    git config --unset "branch.$branch.vscode-merge-base"
  done
  return 0
}
alias tmp="git add . && git commit -m 'tmp' -n"
alias ci="gc -m 'Empty for CI' --allow-empty -n"
# dd-pr() {
#  open "https://github.com/$(git config --get remote.origin.url | cut -d ":" -f 2 | cut -d "." -f 1)/compare/$(git name-rev --name-only HEAD)?expand=1"
#}

# Brew
alias bu="brew upgrade"
alias bcu="brew cask upgrade"

# Sweet utils
who-listen() {
  lsof -t -i :$1
}
kill-listening() {
  kill -9 $(who-listen $1)
}
time_ms() {
  ts=$(date +%s%N)
  $@
  echo "$((($(date +%s%N) - $ts)/1000000))ms"
}
# https://unix.stackexchange.com/questions/11856/sort-but-keep-header-line-at-the-top
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}
set-personal-git() {
  git config user.name "Ayc0"
  git config user.email "ayc0.benj@gmail.com"
}
# https://gist.github.com/mplinuxgeek/dcbc3a4d0f51f2b445608e3da832ebb5
convert_gif() {
  # Usage function, displays valid arguments
  usage() {
    echo "Usage: $(basename ${0}) [arguments] inputfile [outputfile]" 1>&2
    echo "  -l  loop, defaults to 0" 1>&2
    echo "  -f  fps, defaults to 15" 1>&2
    echo "  -w  width, defaults to 480" 1>&2
    echo "  -d  dither level, value between 0 and 5, defaults to 5" 1>&2
    echo "                    0 is no dithering and large file" 1>&2
    echo "                    5 is maximum dithering and smaller file" 1>&2
    echo -e "\nExample: $(basename ${0}) -w 320 -f 10 -d 1" 1>&2
    return 1
  }

  # Default variables
  loop=0
  fps=15
  width=1000
  dither=5

  # getopts to process the command line arguments
  while getopts ":l:f:w:d:" opt; do
      case "${opt}" in
          l) loop=${OPTARG};;
          f) fps=${OPTARG};;
          w) width=${OPTARG};;
          d) dither=${OPTARG};;
          *) usage;;
      esac
  done

  # shift out the arguments already processed with getopts
  shift "$((OPTIND - 1))"
  if (( $# == 0 )); then
      printf >&2 'Missing input file\n'
      usage >&2
  fi

  # set input variable to the first option after the arguments
  input="$1"

  # Extract filename from input file without the extension
  filename=$(basename "$input")
  #extension="${filename##*.}"
  filename="${filename%.*}.gif"
  filename="${2:-$filename}"

  # Debug display to show what the script is using as inputs
  echo "Input: ${1}"
  echo "Output: ${filename}"
  echo "Loop: ${loop}"
  echo "FPS: ${fps}"
  echo "Width: ${width}"
  echo "Dither Level: ${dither}"

  # loop -1 = no loop, and loop 0 = infinity
  loop=$(($loop - 1))

  # temporary file to store the first pass palette
  palette="/tmp/palette.png"

  # options to pass to ffmpeg
  filters="fps=${fps},scale=${width}:-1:flags=lanczos"

  # ffmpeg first pass
  echo -ne "\nffmpeg 1st pass... "
  ffmpeg -v warning -i "${input}" -vf "${filters},palettegen=stats_mode=diff" -y "${palette}" && echo "done"

  # ffmpeg second pass
  echo -ne "ffmpeg 2nd pass... "
  ffmpeg -v warning -i "${input}" -i "${palette}" -loop "${loop}" -lavfi "${filters} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=${dither}" -y "${filename}" && echo "done"

  # display output file size
  filesize=$(du -h "${filename}" | cut -f1)
  echo -e "\nOutput File Name: ${filename}"
  echo "Output File Size: ${filesize}"
}
