#!/bin/zsh
#
#
#	Author:	Timothy J. Luoma
#	Email:		luomat at gmail dot com
#	Date:		2012-02-21
#
#	Purpose: 	Find duplicates in Dropbox
#
#
#	MAKE_PUBLIC:

NAME="$0:t"

die ()
{
        echo "$NAME: $@"
        exit 1
}


# mdfind filename:"'s conflicted copy " -onlyin ~/Dropbox | fgrep "'s conflicted copy "

zmodload zsh/datetime

TIME=`strftime %Y-%m-%d--%H.%M.%S "$EPOCHSECONDS"`

DROPBOX="$HOME/Dropbox"

OUTPUT="/tmp/$NAME:r.txt"

cd "$DROPBOX" || die "Failed to chdir to \$DROPBOX at ${DROPBOX}"

find * -path "*(*'s conflicted copy [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])*" -print > "$OUTPUT"

LINES=`wc -l "$OUTPUT" | awk '{print $1}'`

if [ "$LINES" = "0" ]
then
		exit 0
elif [ "$LINES" = "1" ]
then
		FILE=`cat $OUTPUT`


		if [[ "$LAUNCHD" = "yes" ]]
		then

			msg "Found one duplicate: $FILE"
		fi

		open -R "$FILE"

		exit

else

		if [[ "$LAUNCHD" = "yes" ]]
		then

			msg "Found $LINES duplicates"
			exit 0
		fi

		echo "$NAME: Found $LINES duplicates"

fi



echo -n "$NAME: Do you want to process the duplicates? [Y(es)/n(o)/l(ist)] "
read REPLY

case "$REPLY" in
	n*|N*)
			echo "$NAME: Not processing duplicates. They can be found at $OUTPUT."
			exit 0
	;;

	l*|L*)
			clear
			echo "\n\n$NAME: Showing $OUTPUT"
			cat $OUTPUT
			exit 0
	;;

esac


#########|#########|#########|#########|#########|#########|#########|#########



#########|#########|#########|#########|#########|#########|#########|#########

DIFF=`command which bbdiff || command which diff`


IFS=$'\n' DUPS=(`IFS=$'\n' cat $OUTPUT`)

COUNT=0

for DUP in $DUPS
do
	((COUNT++))


	if [[ -e "$DUP" ]]
	then

		MASTER=`echo "$DUP" | sed "s# (.*'s conflicted copy [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])##g"`

		if [ -e "$MASTER" ]
		then

				SAME=no

				cmp -s "$MASTER" "$DUP" && SAME=yes

				if [ "$SAME" = "yes" ]
				then

						echo "$NAME: files are identical, trashing $DUP"

						mv -vf "$DUP" ~/.Trash/

				else

					echo '\n\n'

					/bin/echo -n "$NAME: $COUNT/$LINES: Processing $DUP [press enter to continue, SU to sort uniq,  T to Trash, D to diff, R to reveal] "

					read ACTION

					case "$ACTION" in
						t*|T*)
								mv -fv "$DUP" ~/.Trash/
						;;

						su*|SU*)

								cat "$DUP" "$MASTER" | sort -u | command pbcopy || die "Failed to copy $DUP and $MASTER to pasteboard"

								command pbpaste > "$MASTER" || die "Failed to paste new info to $MASTER"

								mv -fv "$DUP" ~/.Trash/

								ls -l "$MASTER"

						;;

						d*|D*)
								command echo -n "running $DIFF $MASTER $DUP (Press enter to continue)"

								${DIFF} "$MASTER" "$DUP"

								read NULL

							;;

						r*|R*)
								open -R "$DUP"

								read NULL

							;;

					esac

				fi # files are SAME

		else
				FOUND_MASTER=no
		fi


	else
		echo "$DUP not found"
	fi
done

exit 0
#EOF

