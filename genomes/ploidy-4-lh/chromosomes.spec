[DEFAULT]
substitutions.model = lognormal
substitutions.mean = 2.98
substitutions.sigma = 1.31
substitutions.loc = 250

insertions.model = 0

deletions.model = lognormal
deletions.mean = 7.34
deletions.sigma = 1.123

deletion_size.model = exponential
deletion_size.lambda = 0.2

dosage_dist.1 = 1.0
dosage_dist.2 = 3/4, 1/4
dosage_dist.3 = 1/2, 2/6, 1/6
dosage_dist.4 = 1/2, 2/8, 1/8, 1/8
dosage_dist.5 = 2/5, 3/10, 1/10, 1/10, 1/10
dosage_dist.6 = 4/12, 3/12, 2/12, 1/12, 1/12, 1/12
dosage_dist.7 = 6/16, 4/16, 2/16, 1/16, 1/16, 1/16, 1/16
dosage_dist.8 = 6/16, 3/16, 2/16, 1/16, 1/16, 1/16, 1/16, 1/16

[BK006947.3]
ploidy = 4
