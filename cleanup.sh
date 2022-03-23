# Rewrite the dataset in a libsvm compatible format,
# skipping the first feature which is the Abalone’s age,
# and turning the Abalone’s sex in 3 binary features.
awk -F, '
BEGIN {
sex["M"] = "1:1 2:0 3:0";
sex["F"] = "1:0 2:1 3:0";
sex["I"] = "1:0 2:0 3:1";
}
{
class = ($NF <= 9) ? -1 : 1;
printf("%d %s", class, sex[$1]);
for (i = 2; i <= NF - 1; ++i)
printf(" %d:%s", i + 2, $i);
printf("\n");
}' data/abalone.data.txt > data/dataset.txt
# Split in training and test set.
awk 'NR <= 3133 { print; }' data/dataset.txt > output/train.txt
awk 'NR > 3133 { print; }' data/dataset.txt > output/test.txt
# Scale training and test set.
libsvm-3.0/svm-scale -s output/scale.txt \
output/train.txt > output/train.scaled.txt
libsvm-3.0/svm-scale -r output/scale.txt \
output/test.txt > output/test.scaled.txt