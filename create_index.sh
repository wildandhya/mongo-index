#!/bin/bash

# commands=("mongosh" "jq")

# for command in "${commands[@]}"; do
#     if command -v $command
#     then 
#         echo "$command is available, skipping installation..."
#     else
#         echo "$command is NOT available, installing it..."
#         brew install $command
#     fi
# done



MONGODB_URI="mongodb://localhost:27017"

DB_NAME="test"

JSON_FILE="collection_index.json"


create_indexes(){
    indexes=$(cat "$JSON_FILE")

    for index_definition in $(echo "$indexes" | jq -c '.[]'); do
        collection=$(echo "$index_definition" | jq -r '.collection')
        indexKeys=$(echo "$index_definition" | jq -c '.indexKeys')
        indexProperties=$(echo "$index_definition" | jq -c '.indexProperties')
        indexName=$(echo "$indexProperties" | jq -r '.name')

        echo "Creating index for collection: $collection, name: $indexName, properties: $indexProperties"

        # Check if the index already exists
        indexExists=$(mongosh "$MONGODB_URI/$DB_NAME" --quiet --eval "var indexExists = db.getCollection('$collection').getIndexes().some(function(index) { return index.name === '$indexName'; }); indexExists;")

        if [[ "$indexExists" == "false" ]]; then
            # Build the index creation command as a string
            indexCreationCommand="db.${collection}.createIndex(${indexKeys}, ${indexProperties});"

            # Execute the command using the mongo shell
            mongosh "$MONGODB_URI/$DB_NAME" --eval "$indexCreationCommand"

            echo "Index created for collection: $collection, name: $indexName"
        else
            echo "Index '$indexName' already exists in collection: $collection, skipping..."
        fi
    done
}

create_indexes
