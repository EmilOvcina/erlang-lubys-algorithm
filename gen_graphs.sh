#!/bin/bash
DIR="artefact/tests/generated"
for i in {1..10} 
do
    for j in {1..10} 
    do
        NUM=$(($j * 5))
        NAME=($i\_$NUM)
        python3 graph_gen.py $NUM > $DIR/$NAME.txt
    done
done