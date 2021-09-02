#!/bin/bash
# PeopleHelp Zendesk Toolbox
# Project Mackinac
# Lyft, Inc.
# Sam Mosher smosher@lyft.com

### About this script
#
# This script will download the ticket field and form data from a SOURCE Zendesk and upload it to a TARGET Zendesk
# The script does NOT copy existing ticket data, users, or any other values! ONLY ticket fields and ticket forms

### What do the functions do?
#
# The extractfields function obtains ticket field IDs from source ZD and creates JSON files for those fields
# The extractforms function obtains ticket form IDs from source ZD and creates JSON files for those forms
# The createfields function uploads ticket field JSON files to target ZD and creates a mapping file for old -> new ticket field IDs
# The rewriteticketformid function replaces old ticket field IDs in ticket form JSON files w/ new field IDs
# The createforms function uploads the rewritten ticket form JSON files into the TARGET Zendesk

### Important notes
# One manual step: Once the ticket field map CSV is created, you will be promped to EDIT the CSV file.
# This is because there will be some fields that cannot be automatically created in Zendesk: System 
# fields (Subject, etc.) and dropdown fields where the tag is already in use.
# Before proceeding with STEP 4 of this script: Replace any "ERR_CHECK_FOR_EXISTING" with the NEW
# ticket field ID by cross-referencing the source and target Zendesk tenants.
#
# You must also already have Zendesk API credentials created - you'll be prompted for creds for both the SOURCE and the TARGET Zendesk


extractfields() {

	curl https://"$zensrctenant".zendesk.com/api/v2/ticket_fields.json -v -u "$zensrcuser"/token:""$zensrctoken"" | jq -r '.ticket_fields[] | .id' >> ticket_field_ids.csv

	ticketFieldID=( $(cut -d ',' -f2 ./ticket_field_ids.csv ) )
	ticketFieldIDLength=${#ticketFieldID[@]}


	for (( i=0; i<$ticketFieldIDLength; i++ )); do 
	
		curl https://"$zensrctenant".zendesk.com/api/v2/ticket_fields/"${ticketFieldID[$i]}".json -v -u "$zensrcuser"/token:""$zensrctoken"" >> "${ticketFieldID[$i]}".json
	
	done

}

extractforms() {

	curl https://"$zensrctenant".zendesk.com/api/v2/ticket_forms.json?active=true -v -u "$zensrcuser"/token:""$zensrctoken"" | jq '.ticket_forms[] | .id' >> ticket_form_ids.csv

	ticketFormID=( $(cut -d ',' -f2 ./ticket_form_ids.csv ) )
	ticketFormIDLength=${#ticketFormID[@]}

	for (( i=0; i<$ticketFormIDLength; i++ )); do 

		curl https://"$zensrctenant".zendesk.com/api/v2/ticket_forms/"${ticketFormID[$i]}" -v -u "$zensrcuser"/token:""$zensrctoken"" >> "${ticketFormID[$i]}".json
	
	done

}

createfields() {

	for (( i=0; i<$ticketFieldIDLength; i++ )); do 

		createfield=$(curl https://"$zentgttenant".zendesk.com/api/v2/ticket_fields.json -d @./"${ticketFieldID[$i]}".json -H "Content-Type: application/json" -X POST -v -u "$zentgtuser"/token:""$zentgttoken"" | jq -r '.ticket_field.id')

			if [ "$createfield" != "null" ]; then
		
				printf "${ticketFieldID[$i]}"",""$createfield"'%s\n' >> mapped_ticket_field_ids.csv

			else

				printf "${ticketFieldID[$i]}"",""ERR_CHECK_FOR_EXISTING"'%s\n' >> mapped_ticket_field_ids.csv

			fi

	done

}

rewriteticketformid() {

	for (( i=0; i<$ticketFormIDLength; i++ )); do 

		awk -F',' 'NR==FNR {a[$1]=$2;next} { for(x in a) gsub(x,a[x]) } 1' ./mapped_ticket_field_ids.csv "${ticketFormID[$i]}".json | jq >> "${ticketFormID[$i]}"_rewrite.json

	done

}

createforms() {

	for (( i=0; i<$ticketFormIDLength; i++ )); do

		curl https://"$zentgttenant".zendesk.com/api/v2/ticket_forms.json -H "Content-Type: application/json" -X POST -d @./"${ticketFormID[$i]}"_rewrite.json -v -u "$zentgtuser"/token:""$zentgttoken""	

	done
}

echo "*----------* ################################################# *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* ################################################# *----------*"
echo ""
echo ""
echo "This script is intended to EXTRACT and then PUBLISH the ticket fields and forms from one Zendesk tenant to another."
echo ""
echo "Any previously created data will *not* be overwritten."
echo ""
echo "To start, let's get some info on your Zendesk tenants."
sleep 1;
echo "We need information about the S O U R C E Zendesk tenant."
sleep 1;
read -p "Zendesk SOURCE tenant ({tenant}.zendesk.com):" zensrctenant
read -p "Zendesk SOURCE API Username:" zensrcuser
read -s -p "Zendesk SOURCE API Secret Token:" zensrctoken
echo ""
echo "...ok!"
sleep 1;
echo "We need information about the T A R G E T Zendesk tenant now."
sleep 1;
read -p "Zendesk TARGET tenant ({tenant}.zendesk.com):" zentgttenant
read -p "Zendesk TARGET API Username:" zentgtuser
read -s -p "Zendesk TARGET API Secret Token:" zentgttoken
echo ""
echo "...ok!"
sleep 1;
echo "Let's get started..."
echo "1. EXTRACT TICKET FIELDS FROM $zensrctenant"
extractfields
echo "Step 1 done!"
echo "2. EXTRACT TICKET FORMS FROM $zensrctenant"
extractforms
echo "Step 2 done!"
echo "3. CREATE TICKET FIELDS IN $zentgttenant"
createfields
echo "Step 3 done!"
clear
echo "*----------* ################################################# *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* P E O P L E O P S     Z E N D E S K     T O O L S *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* ############## S T O P    S T O P ############### *----------*"
echo "*----------* ############## S T O P    S T O P ############### *----------*"
echo "*----------* ############## S T O P    S T O P ############### *----------*"
echo "*----------* ############## S T O P    S T O P ############### *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* # YOU MUST EDIT THE MAPPED_TICKET_FIELD_IDS.CSV # *----------*"
echo "*----------* # BEFORE CONTINUING! OTHERWISE FORMS WILL FAIL! # *----------*"
echo "*----------* #_______________________________________________# *----------*"
echo "*----------* #_______________________________________________# *----------*"
echo "*----------* # Replace any ERR_CHECK_FOR_EXISTING entries in # *----------*"
echo "*----------* # column B of MAPPED_TICKET_FIELD_IDS.CSV with  # *----------*"
echo "*----------* #  matching ID from the TARGET Zendesk tenant.  # *----------*"
echo "*----------* #_______________________________________________# *----------*"
echo "*----------* # Once errors are resolved, SAVE the CSV and go # *----------*"
echo "*----------* # onto the next step of this script. Ready? :)  # *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* ################################################# *----------*"
echo "*----------* # S e l e c t   Y E S   w h e n   r e a d y ! ! # *----------*"
echo "*----------* ################################################# *----------*"
PS3='Did you edit mapped_ticket_field_ids.csv, and are you READY to proceed?: '
options=("Yes" "No")
  select opt in "${options[@]}"
  do
    case $opt in
      "Yes")
          echo "OK, sit tight..."
          echo ""
          echo "4. REWRITE TICKET IDS IN FORMS"
          rewriteticketformid
          echo "Step 4 done!"
          echo "5. CREATE TICKET FORMS IN $zentgttenant"
          createforms
          echo "Step 5 done!"
          echo ""
          echo ""
          echo "Ticket fields and forms have been successfully copied from $zensrctenant to $zentgttenant !"
          sleep 2;
          echo "Exiting Zendesk tool now..."
          exit 0
          ;;
      "No")
          echo "OK, try again!"
          ;;
      *) echo invalid option;;
    esac
done