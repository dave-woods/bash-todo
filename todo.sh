#!/bin/bash

usage="Usage: todo [-a item-to-add] [-c item-completed] [-u item-to-uncomplete] [-d item-to-delete] [-l c(ompleted)/u(ncompleted)/d(eleted)/all]"
ccat="$HOME/.scripts/color-cat.sh"
todofile="$HOME/tmp/TODO"
numreg='^[0-9]+$'

make_update () {
	local query="$1"
	local char="$2"
	occ=$(grep -i "$query" $todofile)
	count=$(echo "$occ" | wc -l)
	if [ "$occ" = "" ]; then
		echo "String $query not found"
	elif [ $count -eq 1 ]; then
		handle_single
	elif [ $count -ge 2 ]; then
		handle_multiple
	fi
}

handle_single () {
		rep="$char${occ:1}"
		sed -e "s/$occ/$rep/" -i --follow-symlinks $todofile
		echo "$rep" | "$ccat"
}

handle_multiple () {
	readarray -t arr <<<"$occ"
	echo "Multiple:"
	for i in "${!arr[@]}"; do
		echo "$i: ${arr[$i]:2}"
	done
	read -p "Enter numeric selection (or 'a' for all): " choice
	while { [ "$choice" != "a" ]; } && { ! [[ "$choice" =~ $numreg ]] || { [ "$choice" -lt 0 ] || [ "$choice" -ge "$count" ]; } }
	do
		echo "Unrecognised option"
		read -p "Enter numeric selection (or 'a' for all): " choice
	done
	if [ "$choice" == "a" ]; then
		for i in "${!arr[@]}"; do
			occ="${arr[$i]}"
			handle_single
		done
	else
		occ="${arr[$choice]}"
		handle_single
	fi
}

if [ "$#" = 0 ]; then
	grep "^-" $todofile | $ccat
	exit 0
fi

if [ $(($# % 2)) = 1 ]; then
	echo $usage
	exit 1
fi

while (( "$#" ))
do
	case "$1" in
		"-a")
			echo "- $2" >> $todofile
			echo "- $2" | "$ccat"
			shift
			shift
			;;
		"-c")
			make_update "$2" "*"
			shift
			shift
			;;
		"-u")
			make_update "$2" "-"
			shift
			shift
			;;
		"-d")
			make_update "$2" "#"
			shift
			shift
			;;
		"-l")
			case "$2" in
				"c")
					grep "^\*" $todofile | $ccat
					;;
				"u")
					grep "^-" $todofile | $ccat
					;;
				"d")
					grep "^#" $todofile | $ccat
					;;
				"all")
					$ccat $todofile
					;;
				*)
					echo $usage
					exit 1
					;;
			esac
			shift
			shift
			;;
		*)
			echo "Unknown parameter $1 - skipping $2..."
			shift
			shift
			;;
	esac
done
