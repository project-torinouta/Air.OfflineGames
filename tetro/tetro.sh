#!/bin/bash

true=1
false=0

# Notice the color defined below is just for my kitty + everforest terminal, if
# you don't adjust to them you can also modify.

color_background_black=47

color_foreground_red=31
color_foreground_green=32
color_foreground_yellow=33
color_foreground_blue=34
color_foreground_purple=35
color_foreground_teal=36
color_foreground_white=37

color_foreground=(
  $color_foreground_red
  $color_foreground_green
  $color_foreground_yellow
  $color_foreground_blue
  $color_foreground_purple
  $color_foreground_teal
)

tetromino_straight_state_1=(
  0 0 1 0
  0 0 1 0
  0 0 1 0
  0 0 1 0
)
tetromino_straight_state_2=(
  0 0 0 0
  1 1 1 1
  0 0 0 0
  0 0 0 0
)
tetromino_square=(
  0 1 1 0
  0 1 1 0
  0 0 0 0
  0 0 0 0
)
tetromino_t_shaped_state_1=(
  0 0 0 0
  0 1 1 1
  0 0 1 0
  0 0 0 0
)
tetromino_t_shaped_state_2=(
  0 0 1 0
  0 1 1 0
  0 0 1 0
  0 0 0 0
)
tetromino_t_shaped_state_3=(
  0 0 1 0
  0 1 1 1
  0 0 0 0
  0 0 0 0
)
tetromino_t_shaped_state_4=(
  0 0 1 0
  0 0 1 1
  0 0 1 0
  0 0 0 0
)

# Bash doesn't have two-dimensional array so we should use one-dimensional
# reference array to simulate.

tetrominoes=(
  "tetromino_straight_state_1"
  "tetromino_straight_state_2"
  "tetromino_square"
  "tetromino_t_shaped_state_1"
  "tetromino_t_shaped_state_2"
  "tetromino_t_shaped_state_3"
  "tetromino_t_shaped_state_4"
)

sleep_gap=0.5
playfield_width=30
playfield_height=20
tetromino_block_length=4
is_game_over=$false
current_x=0
current_y=0
current_color=0

declare -ga playfield=()
declare -ga empty=()
declare -gn current_tetromino="$empty"
declare -gn next_tetromino="$empty"
current_tetromino_name=""
next_tetromino_name=""

# This procedure initializes the playfield and use one-dimensional array to
# simulate the two-dimensional array.

for ((i=0; i<$(( $playfield_height + $tetromino_block_length )); i++)); do
  for ((j=0; j<$playfield_width; j++)); do
    index=$(( $i * $playfield_height + $j))
    playfield[$index]=0
  done
done

# Bash cannot pass array into functions but can use references.
# Bash cannot return array from functions but can use references.

function get_random_element() {
  local array_name="$1"
  local -n array="$array_name"

  local element="${array[$(( RANDOM % ${#array[@]} ))]}"
  printf "%s" "$element"
}

function new_tetromino() {
  if [[ ${#current_tetromino[@]} -eq 0 && ${#next_tetromino[@]} -eq 0 ]]; then
    current_tetromino_name="$( get_random_element tetrominoes )"
    next_tetromino_name="$( get_random_element tetrominoes )"
    declare -gn current_tetromino="$current_tetromino_name"
    declare -gn next_tetromino="$next_tetromino_name"
  else
    current_tetromino_name=$next_tetromino_name
    next_tetromino_name="$( get_random_element tetrominoes )"
    declare -gn current_tetromino="$current_tetromino_name"
    declare -gn next_tetromino="$next_tetromino_name"
  fi

  current_y=0
  current_x=$(( ($playfield_width - $tetromino_block_length) / 2 ))
  current_color=$( get_random_element color_foreground )
}
new_tetromino

function is_two_tetromino_equal() {
  if [[ ${#1[@]} -ne ${#2[@]} ]]; then
    echo -e "\033[${color_foreground_red}mThe length of two tetrominoes are not equal\033[0m"
    exit 2
  fi

  for ((i=0; i < ${#1[@]}; i++)); do
    if [[ ${1[$i]} -ne ${2[$i]} ]]; then
      return $false
    fi
  done
  return $true
}

function rotate_current_tetromino() {
  if [[ $( is_two_tetromino_equal current_tetromino tetromino_straight_state_1 ) -eq $true ]]; then
    current_tetromino=tetromino_straight_state_2
    return
  elif [[ $( is_two_tetromino_equal current_tetromino tetromino_straight_state_2 ) -eq $true ]]; then
    current_tetromino=tetromino_straight_state_1
    return
  fi
}

function test_collision() {
  x=$1
  y=$2
  for ((i=0; i < $tetromino_block_length; i++)); do
    for ((j=0; j < $tetromino_block_length; j++)); do
      local test_x=$(( $x + $j ))
      local test_y=$(( $y + $i ))
      if [[ \
        ${current_tetromino[$(( $i * $tetromino_block_length + $j ))]} -eq 1 && \
        (${playfield[$(( $test_y * $playfield_width + $test_x ))]} -ne 0 || \
         $test_y -ge $(( $playfield_height + $tetromino_block_length )) || \
         $test_x -lt 0 || \
         $test_x -ge $playfield_width)
      ]]; then
        printf "%d" $true
      fi
    done
  done
  printf "%d" $false
}

function update_game() {
  # Clear the last drawn current tetromino

  for ((i=0; i < $tetromino_block_length; i++)); do
    for ((j=0; j < $tetromino_block_length; j++)); do
      local tetromino_index=$(( $i * $tetromino_block_length + $j ))
      local index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
      if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
        playfield[$index]=0
      fi
    done
  done

  # $() can contain function calling but $(()) is the arithmetic expression

  if [[ $( test_collision $current_x $(( $current_y + 1 )) ) -eq "$false" ]]; then
    current_y=$(( $current_y + 1 ))
    for ((i=0; i < $tetromino_block_length; i++)); do
      for ((j=0; j < $tetromino_block_length; j++)); do
        local tetromino_index=$(( $i * $tetromino_block_length + $j ))
        if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
          local index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
          playfield[$index]=$current_color
        fi
      done
    done
  else
    for ((i=0; i < $tetromino_block_length; i++)); do
      for ((j=0; j < $tetromino_block_length; j++)); do
        local tetromino_index=$(( $i * $tetromino_block_length + $j ))
        if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
          index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
          playfield[$index]=$current_color
        fi
      done
    done
    new_tetromino
  fi
}

function draw_game() {
  tput cup 0 0

  # Use tput to place the cursor to left-up corner and decrease the re-render

  for ((i=$tetromino_block_length; i < $(( $playfield_height + $tetromino_block_length )); i++)); do
    echo -n "  "
    for ((j=0; j < $playfield_width; j++)); do
      index=$(( $i * $playfield_width + $j ))
      if [[ ${playfield[$index]} -ne 0 ]]; then
        echo -ne "\033[${playfield[$index]};${color_background_black}m#\033[0m"
      else
        echo -ne "\033[;${color_background_black}m \033[0m"
      fi
    done
    echo ""
  done
}

function left_arrow() {
  for ((i=0; i < $tetromino_block_length; i++)); do
    for ((j=0; j < $tetromino_block_length; j++)); do
      local tetromino_index=$(( $i * $tetromino_block_length + $j ))
      local index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
      if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
        playfield[$index]=0
      fi
    done
  done

  if [[ $( test_collision $(( $current_x - 1 )) $current_y ) -eq $false ]]; then
    current_x=$(( $current_x - 1))
    for ((i=0; i < $tetromino_block_length; i++)); do
      for ((j=0; j < $tetromino_block_length; j++)); do
        local tetromino_index=$(( $i * $tetromino_block_length + $j ))
        if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
          local index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
          playfield[$index]=$current_color
        fi
      done
    done
  else
    for ((i=0; i < $tetromino_block_length; i++)); do
      for ((j=0; j < $tetromino_block_length; j++)); do
        local tetromino_index=$(( $i * $tetromino_block_length + $j ))
        if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
          index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
          playfield[$index]=$current_color
        fi
      done
    done
  fi
}

echo -e "\033c"
tput civis
stty -echo
trap "stty -raw echo; tput cnorm; echo -e '\nExit Tetro by user input'; exit 0" SIGINT SIGTERM EXIT
while [ $is_game_over -ne $true ]; do
  if read -n 1 -t $sleep_gap key; then
    case "$key" in
      $'\e')
        if read -n 2 -t 0.1 esc_sequence; then
          case "$esc_sequence" in
            "[A") ;;
            "[B") ;;
            "[C") ;;
            "[D") left_arrow; draw_game ;;
          esac
        fi
      ;;
      [qQ]) echo -e "\nExit Tetro by user input"; exit 0 ;;
    esac
  fi
  update_game
  draw_game
  sleep $sleep_gap
done
