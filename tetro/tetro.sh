#!/bin/bash

stty -echo -icanon

true=1
false=0

log_filename="$( pwd )/$( date +"%Y-%m-%d_%H-%M-%S" ).log"
show_log=$false

if [[ $1 == "--show-log" ]]; then
  show_log=$true
  rm ./*.log
  touch $log_filename
fi

# Notice the color defined below is just for my kitty + everforest terminal, if
# you don't adjust to them you can also modify.

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
tetromino_j_shaped_state_1=(
  0 0 1 0
  0 0 1 0
  0 1 1 0
  0 0 0 0
)
tetromino_j_shaped_state_2=(
  0 1 0 0
  0 1 1 1
  0 0 0 0
  0 0 0 0
)
tetromino_j_shaped_state_3=(
  0 0 1 1
  0 0 1 0
  0 0 1 0
  0 0 0 0
)
tetromino_j_shaped_state_4=(
  0 0 0 0
  0 1 1 1
  0 0 0 1
  0 0 0 0
)
tetromino_l_shaped_state_1=(
  0 0 1 0
  0 0 1 0
  0 0 1 1
  0 0 0 0
)
tetromino_l_shaped_state_2=(
  0 0 0 0
  0 1 1 1
  0 1 0 0
  0 0 0 0
)
tetromino_l_shaped_state_3=(
  0 1 1 0
  0 0 1 0
  0 0 1 0
  0 0 0 0
)
tetromino_l_shaped_state_4=(
  0 0 0 1
  0 1 1 1
  0 0 0 0
  0 0 0 0
)
tetromino_z_shaped_state_1=(
  0 0 0 0
  1 1 0 0
  0 1 1 0
  0 0 0 0
)
tetromino_z_shaped_state_2=(
  0 1 0 0
  1 1 0 0
  1 0 0 0
  0 0 0 0
)
tetromino_s_shaped_state_1=(
  0 0 0 0
  0 1 1 0
  1 1 0 0
  0 0 0 0
)
tetromino_s_shaped_state_2=(
  1 0 0 0
  1 1 0 0
  0 1 0 0
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
  "tetromino_j_shaped_state_1"
  "tetromino_j_shaped_state_2"
  "tetromino_j_shaped_state_3"
  "tetromino_j_shaped_state_4"
  "tetromino_l_shaped_state_1"
  "tetromino_l_shaped_state_2"
  "tetromino_l_shaped_state_3"
  "tetromino_l_shaped_state_4"
  "tetromino_z_shaped_state_1"
  "tetromino_z_shaped_state_2"
  "tetromino_s_shaped_state_1"
  "tetromino_s_shaped_state_2"
)

update_interval=400000000
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

for ((i=0; i < $(( $playfield_height + $tetromino_block_length )); i++)); do
  for ((j=0; j < $playfield_width; j++)); do
    index=$(( $i * $playfield_height + $j))
    playfield[$index]=0
  done
done

function log_file() {
  local level=$1
  local message=$2

  if [[ $show_log -eq $true ]]; then
    printf "[%s] [%-5s] : %s\n" "$( date +"%Y-%m-%d %H:%M:%S:%N")" "$level" "$message" >> $log_filename
  fi
}

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

  log_file "debug" "Reset the new tetromino to ($current_x, $current_y)"
}
new_tetromino

function return_rotated_tetromino_name() {
  case $current_tetromino_name in
    tetromino_straight_state_1)
      printf "tetromino_straight_state_2";;
    tetromino_straight_state_2)
      printf "tetromino_straight_state_1";;
    tetromino_square)
      printf "tetromino_square";;
    tetromino_t_shaped_state_1)
      printf "tetromino_t_shaped_state_2";;
    tetromino_t_shaped_state_2)
      printf "tetromino_t_shaped_state_3";;
    tetromino_t_shaped_state_3)
      printf "tetromino_t_shaped_state_4";;
    tetromino_t_shaped_state_4)
      printf "tetromino_t_shaped_state_1";;
    tetromino_j_shaped_state_1)
      printf "tetromino_j_shaped_state_2";;
    tetromino_j_shaped_state_2)
      printf "tetromino_j_shaped_state_3";;
    tetromino_j_shaped_state_3)
      printf "tetromino_j_shaped_state_4";;
    tetromino_j_shaped_state_4)
      printf "tetromino_j_shaped_state_1";;
    tetromino_l_shaped_state_1)
      printf "tetromino_l_shaped_state_2";;
    tetromino_l_shaped_state_2)
      printf "tetromino_l_shaped_state_3";;
    tetromino_l_shaped_state_3)
      printf "tetromino_l_shaped_state_4";;
    tetromino_l_shaped_state_4)
      printf "tetromino_l_shaped_state_1";;
    tetromino_z_shaped_state_1)
      printf "tetromino_z_shaped_state_2";;
    tetromino_z_shaped_state_2)
      printf "tetromino_z_shaped_state_1";;
    tetromino_s_shaped_state_1)
      printf "tetromino_s_shaped_state_2";;
    tetromino_s_shaped_state_2)
      printf "tetromino_s_shaped_state_1";;
  esac

  return 0
}

function test_collision() {
  local x=$1
  local y=$2
  local input_tetromino_name="$3"
  declare -n test_tetromino="$current_tetromino_name"

  if [[ $input_tetromino_name ]]; then
    declare -n test_tetromino="$input_tetromino_name"
  fi

  for ((i=0; i < $tetromino_block_length; i++)); do
    for ((j=0; j < $tetromino_block_length; j++)); do
      local test_x=$(( $x + $j ))
      local test_y=$(( $y + $i ))

      log_file \
        "debug" \
        "Beginning to debug the collision test procedure for position ($j, $i) ..."

      if [[ ${test_tetromino[$(( $i * $tetromino_block_length + $j ))]} -eq 1 ]]; then
        log_file \
          "debug" \
          "Debugging position ($j, $i) in current tetromino and its a block"
      fi

      if [[ ${playfield[$(( $test_y * $playfield_width + $test_x ))]} -ne 0 ]]; then
        log_file \
          "debug" \
          "Debugging position ($j, $i) in current tetromino, current test
x of tetromino is $x, y of tetromino is $y and position \
($test_x, $test_y) of playfield is already filled."
      fi

      log_file \
        "debug" \
        "Finishing to debug the collision test procedure for position ($j, $i) ..."

      if [[ \
        ${test_tetromino[$(( $i * $tetromino_block_length + $j ))]} -eq 1 && \
        (${playfield[$(( $test_y * $playfield_width + $test_x ))]} -ne 0 || \
         $test_y -ge $(( $playfield_height + $tetromino_block_length )) || \
         $test_x -lt 0 || \
         $test_x -ge $playfield_width)
      ]]; then
        log_file "debug" "Function 'test_collision' returned true"
        printf "%d" $true
        return 0
      fi
    done
  done
  log_file "debug" "Function 'test_collision' returned false"
  printf "%d" $false
  return 0
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

  echo -n "  "
  for ((i=0; i < $playfield_width; i++)); do
    echo -n "="
  done
  echo ""

  for ((i=$tetromino_block_length; i < $(( $playfield_height + $tetromino_block_length )); i++)); do
    echo -n "  "
    for ((j=0; j < $playfield_width; j++)); do
      index=$(( $i * $playfield_width + $j ))
      if [[ ${playfield[$index]} -ne 0 ]]; then
        echo -ne "\033[${playfield[$index]}m#\033[0m"
      else
        echo -ne "\033[m \033[0m"
      fi
    done
    echo ""
  done

  echo -n "  "
  for ((i=0; i < $playfield_width; i++)); do
    echo -n "="
  done
  echo ""
}

function arrow_control() {
  direction=$1
  condition=$false

  log_file "debug" "Read the arrow key '$direction'"

  for ((i=0; i < $tetromino_block_length; i++)); do
    for ((j=0; j < $tetromino_block_length; j++)); do
      local tetromino_index=$(( $i * $tetromino_block_length + $j ))
      local index=$(( ($current_y + $i) * $playfield_width + ($current_x + $j) ))
      if [[ ${current_tetromino[$tetromino_index]} -eq 1 ]]; then
        playfield[$index]=0
      fi
    done
  done

  # Dev-Log: 2025-10-21 02-09-13 The last block must be first cleared before
  # testing the collision

  case "$direction" in
    left)
      condition=$( test_collision $(( $current_x - 1 )) $current_y )
      log_file "debug" "Match the case LeftArrow"
      ;;
    right)
      condition=$( test_collision $(( $current_x + 1 )) $current_y )
      log_file "debug" "Match the case RightArrow"
      ;;
    down)
      condition=$( test_collision $current_x $(( $current_y + 1)) )
      log_file "debug" "Math the case DownArrow"
      ;;
    up)
      condition=$( test_collision $current_x $current_y $( return_rotated_tetromino_name $current_tetromino_name ) )
      log_file "debug" "Match the case UpArrow"
      ;;
  esac

  log_file "debug" "The 'condition' variable has been set to $condition"

  if [[ $condition -eq $false ]]; then
    case "$direction" in
      left)
        current_x=$(( $current_x - 1))
        ;;
      right)
        current_x=$(( $current_x + 1))
        ;;
      down)
        current_y=$(( $current_y + 1))
        ;;
      up)
        current_tetromino_name=$( return_rotated_tetromino_name $current_tetromino_name )
        declare -gn current_tetromino="$current_tetromino_name"
    esac

    log_file "debug" "Move the current tetromino to ($current_x, $current_y)"

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
trap "stty echo icanon; tput cnorm; echo -e '\nExit Tetro by user input'; exit 0" SIGINT SIGTERM EXIT

last_update=$( date +%s%N )
while [ $is_game_over -ne $true ]; do
  if read -n 1 -t 0.05 -r key; then
    log_file "debug" "Read the key '$key' from keyboard"

    case "$key" in
      $'\x1B')
        if read -n 2 -t 0.05 -r esc_sequence; then
          case "$esc_sequence" in
            "[A") arrow_control "up";    draw_game ;;
            "[B") arrow_control "down";  draw_game ;;
            "[C") arrow_control "right"; draw_game ;;
            "[D") arrow_control "left";  draw_game ;;
          esac
        fi
      ;;
      [qQ]) echo -e "\nExit Tetro by user input"; exit 0 ;;
    esac
  fi
  current_time=$( date +%s%N )
  if [[ $(( $current_time - $last_update )) -ge $update_interval ]]; then
    update_game
    last_update=$current_time
  else 
    draw_game
    sleep 0.001
  fi
done
