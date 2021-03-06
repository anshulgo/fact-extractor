#!/bin/bash

set -e

usage="Usage: $(basename "$0") <LEXICAL_UNIT> <WORD_COUNT_THRESHOLD>"
if [[ $# -ne 2 ]]; then
    echo $usage
    exit 1;
fi

cd ..

SENTENCES_DIR="training/sentences/${1}"

if [[ ! -d $SENTENCES_DIR ]]; then
    mkdir $SENTENCES_DIR
fi
echo "Getting list of tokens for lexical unit [${1}] ..."
grep -w $1 verbs/top-50-token2lemma.sorted | cut -f 1 > ${SENTENCES_DIR}/tokens
echo "Got $(wc -l ${SENTENCES_DIR}/tokens) tokens"
echo "Extracting all sentences from corpus, writing to ${SENTENCES_DIR}/all ..."
grep -rhwf ${SENTENCES_DIR}/tokens corpus > ${SENTENCES_DIR}/all
echo "Keeping sentences with less than ${2} words, writing to ${SENTENCES_DIR}/short ..."
while read f; do
    words=$(echo $f | wc -w)
    if [[ $words -lt $2 ]]; then
        echo $f >> ${SENTENCES_DIR}/short
    fi
done < ${SENTENCES_DIR}/all
echo "Getting a random sample of 100 sentences ..."
shuf -n 100 ${SENTENCES_DIR}/short > ${SENTENCES_DIR}/sample
echo "Surrounding lexical units with a <strong> tag ..."
# FIXME find a way to reliably add the tag
sed -r 's/()/<strong>\1<\/strong>/gi' > ${SENTENCES_DIR}/tagged-sample
echo "POS tagging sample sentences ..."
if [[ ! -d ${SENTENCES_DIR}/pos-tagged ]]; then
    mkdir ${SENTENCES_DIR}/pos-tagged
fi
# FIXME the loop only makes 1 iteration only
i=0
while read f; do
    echo $f | treetagger/cmd/tree-tagger-italian > ${SENTENCES_DIR}/pos-tagged/$i
    let i++
done < ${SENTENCES_DIR}/sample
echo "Filtering out meaningful ones, writing to ${SENTENCES_DIR}/gold ..."
python scripts/get_meaningful_sentences.py ${SENTENCES_DIR}/pos-tagged ${SENTENCES_DIR}/tokens ${SENTENCES_DIR}/gold
