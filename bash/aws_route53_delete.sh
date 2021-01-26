#!/bin/sh

# NOTE:
# Make sure that the value of Name, Type, TTL are the same with your DNS Record Set
# Source: https://gist.github.com/earljon/8579429f90c3480c06eb2bc952255987

HOSTED_ZONE_ID=<YOUR_HOSTED_ZONE_ID>
RESOURCE_VALUE=<YOUR_DNS_RESOURCE_VALUE-ex:IP or dns>
DNS_NAME=<YOUR_DNS_NAME-ex: subdomain.domain.com>
RECORD_TYPE=<DNS_RECORD_TYPE-ex: A, CNAME>
TTL=<TTL_VALUE>

JSON_FILE=`mktemp`

(
cat <<EOF
{
    "Comment": "Delete single record set",
    "Changes": [
        {
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "$DNS_NAME.",
                "Type": "$RECORD_TYPE",
                "TTL": $TTL,
                "ResourceRecords": [
                    {
                        "Value": "${RESOURCE_VALUE}"
                    }
                ]                
            }
        }
    ]
}
EOF
) > $JSON_FILE

echo "Deleting DNS Record set"
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE

echo "Deleting record set ..."
echo
echo "Operation Completed."
