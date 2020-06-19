#!/bin/sh

########################################################################################################################
# Usage
#
# cleanup_old_tags.sh
#   - DRY_RUN_ONLY
#       - when true, this WILL NOT delete any tags.
#       - when false, this WILL delete tags.
#   - CUT_OFF_DATE
#       - CUT_OFF_DATE needs to be of YYYYMMDD format.
#       - any tags older than this date will be removed.
#
########################################################################################################################

DRY_RUN_ONLY=false
CUT_OFF_DATE="20200301"

TEMP_FILE="temp_cleanup_old_tags.txt"

echo "cleanup_old_tags.sh executing..."
echo ""

# fetch all tags from the remote
git fetch

# read tags to temporary file
git log --tags --simplify-by-decoration --pretty="format:%ai %d" > $TEMP_FILE

echo "Candidate tags to remove:"
echo ""

REMOVAL_CANDIDATE_TAGS=()

while IFS= read -r line
do
    if [[ $line = *"tag: "* ]]
    then
        LINE_DATE=$(echo ${line:0:10} | tr -d '-')

        if [[ $CUT_OFF_DATE -gt $LINE_DATE ]]
        then
            TAG_STRING=$(echo ${line:28} | tr -d ' ')
            TAG_STRING=${TAG_STRING%?}

            IFS=',' read -ra TAG_ARRAY <<< "$TAG_STRING"
            for tag in "${TAG_ARRAY[@]}"
            do
                if [[ $tag = *"tag:"* ]]
                then
                    SANITIZED_TAG=$(echo $tag | sed -e 's/tag://g')
                    REMOVAL_CANDIDATE_TAGS+=($SANITIZED_TAG)
                fi
            done
        fi
    fi
done < "$TEMP_FILE"

if [[ "${#REMOVAL_CANDIDATE_TAGS[@]}" > 0 ]]
then
    IFS=$'\n'
    SORTED_REMOVAL_CANDIDATE_TAGS=$(sort <<< "${REMOVAL_CANDIDATE_TAGS[*]:1}")
    echo "${SORTED_REMOVAL_CANDIDATE_TAGS[*]}"

    if [[ ! "$DRY_RUN_ONLY" = "true" ]]
    then
        echo ""
        echo "NOT A DRY RUN -- PRESS 'Y' TO PROCEED WITH DELETION OF TAGS"
        echo ""
        read CONFIRM_TAG_CLEANUP
        if [[ "$CONFIRM_TAG_CLEANUP" == "y" ]] || [[ "$CONFIRM_TAG_CLEANUP" == "Y" ]]
        then
            # push deletion on remote
            git push origin --delete ${SORTED_REMOVAL_CANDIDATE_TAGS[*]}

            # delete all local tags that are no longer present on the remote
            git fetch --prune origin +refs/tags/*:refs/tags/*

            echo ""
            echo "DRY_RUN_ONLY=false"
            echo "Tags have been deleted ..."
            echo ""
        else
            echo ""
            echo "Tags have not been deleted ..."
            echo ""
        fi
    else
        echo ""
        echo "DRY_RUN_ONLY=true"
        echo "Tags have not been deleted ..."
        echo ""
    fi
else
        echo ""
        echo "No tags older than $CUT_OFF_DATE ..."
        echo ""
fi

rm -rf $TEMP_FILE

echo ""
echo "cleanup_old_tags.sh done..."
echo ""
