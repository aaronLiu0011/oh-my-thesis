# Gelbach decomposition using the supplied master-data CSV and main DID script.
# Usage: Rscript regression_script/gelbach_decomposition.r [CSV] [output_dir] [draws]
# Requires fixest. Defaults resolve relative to this script's repository.
# Gelbach (2016), Journal of Labor Economics 34(2):509-543.
# https://doi.org/10.1086/683668
# CIs use stratified state-pairs bootstrap, not the paper's analytic variance.
# Outputs include model/decomposition CSVs, sample/bootstrap RDSs and provenance.
script_arg <- grep('^--file=', commandArgs(FALSE), value=TRUE)
script_path <- normalizePath(sub('^--file=', '', script_arg[1]), mustWork=TRUE)
repo_root <- dirname(dirname(script_path))
args <- commandArgs(TRUE)
source_path <- if(length(args)>0) args[1] else file.path(repo_root, 'master-data', 'state_panel_2010_2023.csv')
out <- if(length(args)>1) args[2] else file.path(repo_root, 'out', 'gelbach_decomposition')
B <- if(length(args)>2) as.integer(args[3]) else 1999L
if (length(B)!=1L || is.na(B) || B < 2L) stop('Bootstrap draws must be an integer >= 2')
if (!file.exists(source_path)) stop('Input CSV not found: ', source_path)
dir.create(out, recursive=TRUE, showWarnings=FALSE)
library(fixest)
d <- read.csv(source_path, colClasses=c(fips='character'))
d <- subset(d, year != 2020 & (cohort == 2022 | is.na(cohort)))
d$log_income <- log(d$income)
groups <- list(Demography=c('share_age_15_44','share_male','share_black','share_married_15p'),
               Insurance='uninsured_pct', Education='share_hs_plus_25p',
               Economy=c('unrate','poverty_rate','log_income'))
xs <- unlist(groups, use.names=FALSE)
ys <- c('ch_index','go_index','sy_index','std_index')
original <- d
d <- d[complete.cases(d[,c('did','fips','year',xs,ys)]),]
stopifnot(!anyDuplicated(d[,c('fips','year')]), all(is.finite(as.matrix(d[,c(xs,ys)]))),
          all(d$did == as.integer(!is.na(d$cohort) & d$year >= d$cohort)))
saveRDS(d,file.path(out,'analysis_sample.rds'))
# FWL residualization preserves the state/year FE specification. Scale controls
# for numerical stability; products pi_j * gamma_j are scale invariant.
decompose <- function(a) {
  z <- as.matrix(a[,c('did',xs,ys)])
  z <- fixest::demean(z, f=list(a$fips,a$year))
  D <- z[,1]; X <- z[,1+seq_along(xs),drop=FALSE]
  X <- sweep(X,2,sqrt(colSums(X^2)),'/')
  Y <- z[,1+length(xs)+seq_along(ys),drop=FALSE]
  fit <- lm.fit(cbind(D,X),Y)
  if(fit$rank != 1+length(xs)) stop('Rank deficient bootstrap sample')
  base <- as.vector(crossprod(D,Y)/sum(D^2))
  full <- fit$coefficients[1,]
  pi <- as.vector(crossprod(D,X)/sum(D^2))
  # Positive contribution means ADDING controls INCREASES the DID coefficient.
  contribution <- -sweep(fit$coefficients[-1,,drop=FALSE],1,pi,'*')
  rownames(contribution) <- xs
  stopifnot(max(abs(colSums(contribution)-(full-base))) < 1e-7)
  grouped <- do.call(rbind,lapply(groups,function(g) colSums(contribution[g,,drop=FALSE])))
  ans <- rbind(no_controls=base,full_controls=full,change=full-base,grouped,contribution)
  colnames(ans) <- ys
  ans
}
point <- decompose(d)
# Independent check against the original feols specification and clustered SEs.
model_results <- list()
for(y in ys) for(spec in c('no_controls','full_controls')) {
  rhs <- if(spec=='no_controls') 'did' else paste(c('did',xs),collapse='+')
  m <- feols(as.formula(paste(y,'~',rhs,'| fips + year')),data=d,cluster=~fips)
  stopifnot(abs(coef(m)['did']-point[spec,y])<1e-7)
  ci <- confint(m,'did')
  model_results[[paste(y,spec)]] <- data.frame(outcome=y,spec=spec,n=nobs(m),
       states=length(unique(d$fips)),estimate=coef(m)['did'],se=se(m)['did'],
       p=pvalue(m)['did'],low=unname(ci[1]),high=unname(ci[2]))
}
write.csv(do.call(rbind,model_results),file.path(out,'models.csv'),row.names=FALSE)
# Stratified state-pairs bootstrap: preserve observed treated / control counts;
# resample whole state histories and relabel repeated states as separate units.
set.seed(20260909)
ids <- unique(d$fips)
treated <- ids[vapply(ids,function(id) any(d$did[d$fips==id]==1),logical(1))]
controls <- setdiff(ids,treated)
rows <- split(seq_len(nrow(d)),d$fips)
boot <- array(NA_real_,c(nrow(point),ncol(point),B))
for(b in seq_len(B)) {
  draw <- c(sample(treated,length(treated),TRUE),sample(controls,length(controls),TRUE))
  idx <- unlist(rows[draw],use.names=FALSE)
  a <- d[idx,]; a$fips <- rep(seq_along(draw),lengths(rows[draw]))
  boot[,,b] <- decompose(a)
  if(b %% 500 == 0) cat('Completed',b,'bootstrap draws\n')
}
res <- expand.grid(term=rownames(point),outcome=colnames(point),stringsAsFactors=FALSE)
res$estimate <- as.vector(point)
res$bootstrap_se <- as.vector(apply(boot,c(1,2),sd))
res$ci_low <- as.vector(apply(boot,c(1,2),quantile,probs=.025))
res$ci_high <- as.vector(apply(boot,c(1,2),quantile,probs=.975))
write.csv(res,file.path(out,'decomposition.csv'),row.names=FALSE)
saveRDS(list(point=point,bootstrap=boot,groups=groups,seed=20260909),file.path(out,'bootstrap.rds'))
capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'))
capture.output(list(source=source_path,md5=tools::md5sum(source_path),
  script_reference=file.path(repo_root, 'regression_script', 'did_analysis_main.r'),
  object='CSV',source_rows=nrow(original),common_rows=nrow(d),
  treated_states=treated,control_states=controls,years=sort(unique(d$year)),
  dropped=original[!complete.cases(original[,c('did','fips','year',xs,ys)]),c('fips','year')],
  draws=B),file=file.path(out,'provenance.txt'))
print(res[res$outcome=='ch_index',],row.names=FALSE)
