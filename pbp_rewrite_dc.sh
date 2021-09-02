#!/bin/bash
### Build A/PBP Dynamic Content files
### Sam Mosher smosher@lyft.com

### Builds DC lists for auto CC features

# Set default saved file names
apbpFile="./apbpDC.txt"
pbpFile="./pbpDC.txt"

# Provide file warning
echo -e "\n\n\nYou must do the following prior to proceeding:\nA) Download PBP roster from Workday\nB)REMOVE rows 1-9\nC)FIND and REMOVE all commas in file\nD)SAVE file as MS-DOS CSV\n\n\n"

# Ask for CSV location
read -p "Path to CSV file with A/PBP data:" csvFile

echo -e "\n\n\n"

PS3='Did you: Edit PBP list to remove extraneous columns and rows?: '
options=("Yes" "No")
  select opt in "${options[@]}"
  do
    case $opt in
     "Yes")
		
		# Create array for text
		while IFS=',' read -ra array; do

 			ar1+=("${array[2]}") # First Name
  			ar2+=("${array[1]}") # Last Name
  			ar3+=("${array[27]}") # Email Address

		done < $csvFile

		arLength=${#ar1[@]}

		# Create APBP file
		echo "{% case ticket.requester.custom_fields.okta_apbp %}" >> $apbpFile                                                     

		for (( i=0; i<$arLength; i++ )); do

			echo -e "{% when '${ar1[$i]} ${ar2[$i]}' %}\n${ar3[$i]}\n" >> $apbpFile

		done

		echo -e "{% else %}\nERROR\n{% endcase %}" >> $apbpFile

		echo "File $apbpFile created in current directory!"

		# Create PBP file
		echo "{% case ticket.requester.custom_fields.okta_pbp %}" >> $pbpFile

		for (( i=0; i<$arLength; i++ )); do
			
			echo -e "{% when '${ar1[$i]} ${ar2[$i]}' %}\n${ar3[$i]}\n" >> $pbpFile

		done

		echo -e "{% else %}\nERROR\n{% endcase %}" >> $pbpFile

		echo "File $pbpFile created in current directory!"

		echo -e "This script will output two files in the current directory.\n
			Now, do the following:\n
			1)Copy and paste the text from the two text files created into:\n
			-----Zendesk under Zendesk -> Admin -> Manage -> Dynamic Content -> {A/PBP} Contact List\n
			2) Select "Edit" under Variants\n
			3) Replace current Dynamic Content text\n
			4) Select "Update"\n
			5) Repeat for other PBP Dynamic Content list\n
			\n\n\n"

		exit 0
		;;

	"No")
		echo "OK, try again!"
		;;

	*) echo invalid option;;
	esac
done