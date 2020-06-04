#!/bin/sh

for file in Dockerfile*; do
    tag="$(sed -nE 's/^FROM [^:]+:([^ ]+)/\1/p' "$file" | tail -n 1)"
    docker build -f "$file" --tag "middagj/sonar:$tag" .
    docker push "middagj/sonar:$tag"
done
