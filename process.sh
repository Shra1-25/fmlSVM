# Split the training data into ten equal-sized disjoint sets:
sort -R output/train.scaled.txt \
> output/train.scaled.shuffled.txt
NUM_SAMPLES=$(cat output/train.scaled.shuffled.txt \
| wc --lines)
for SPLIT in $(seq 1 5); do
awk "NR < $NUM_SAMPLES * ($SPLIT - 1) / 5.0 \
|| NR >= $NUM_SAMPLES * $SPLIT / 5.0" \
output/train.scaled.shuffled.txt \
> output/train.$SPLIT.txt
awk "NR >= $NUM_SAMPLES * ($SPLIT - 1) / 5.0 \
&& NR < $NUM_SAMPLES * $SPLIT / 5.0" \
output/train.scaled.shuffled.txt \
> output/dev.$SPLIT.txt
done
# Compute accuracy for different values of $C$ and
# for degrees 1 through 4 of the polynomial kernel.
for LOG2C in $(seq -10 10); do
    for DEGREE in 1 2 3 4 5; do
        for SPLIT in $(seq 1 5); do
        # Train models.
        C=$(python -c "print(3 ** $LOG2C)")
        echo "c="$C "d="$DEGREE "split="$SPLIT
        libsvm-3.0/svm-train -t 1 -d $DEGREE -c $C \
        output/train.$SPLIT.txt \
        output/model.$LOG2C.$DEGREE.$SPLIT.txt \
        > output/train.$LOG2C.$DEGREE.$SPLIT.log.txt
        libsvm-3.0/svm-predict output/dev.1.txt \
        output/model.$LOG2C.$DEGREE.$SPLIT.txt \
        output/dev.$LOG2C.$DEGREE.$SPLIT.prediction.txt \
        > output/dev.$LOG2C.$DEGREE.$SPLIT.log.txt
        done
    done
done
# Compute mean and standard deviation
# of classification accuracy.
echo -n > output/dev.results.txt
for F in output/dev.*.log.txt; do
echo $F $(cat $F) | \
sed 's;.\.\(.\)\.\(.\)\.\(.\)\.log.* = \(.\)%.;\1 \2 \3 \4;' \
| grep -v 'classification' \
>> output/dev.results.txt;
done
awk '{
acc = $4 / 100;
accuracy_mean[$1" "$2] += acc / 5;
accuracy_var[$1" "$2] += acc ^ 2 / (5 - 1);
}
END {
for (cond in accuracy_mean) {
mean = accuracy_mean[cond];
std = sqrt(accuracy_var[cond] - mean ^ 2 * 5/ (5 - 1));
print cond, mean, std;
}
}' output/dev.results.txt \
| sort -n -k 3 > output/dev.results.summary.txt
