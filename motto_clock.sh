# Medieval wall/tower clocks were often decorated
# with latin mottos that encourage to value the time
# and remember one won't live forever
#
# Let's implement it in a modern environment
function clock() {

    mottos=(
              "Vulnerant omnes, ultima necat"    # "Each [hour] hurts, the last one kills"
              "Ultima forsan"                    # "Perhaps the last [hour]"
              "Memento mori"                     # "Remember you are mortal"
              "Tempus fugit"                     # "Time flies"
              "Vita brevis"                      # "Life is short"
            )

    date "${@}"
    echo ${mottos[$(($RANDOM%${#mottos[@]}))]}
}

clock
