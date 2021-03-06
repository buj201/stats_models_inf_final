setwd("~/Desktop/MS_Courses/Stats_inf_regression/stats_models_inf_final/Final_project")

MgMI = read.csv('data/magnesium.csv', )

early_studies = c('Morton','Rasmussen','Smith','Abraham','Feldstedt','Schechter','Ceremuzynski','LIMIT-2')

middle_studies = c('Bertschat','Singh','Pereira','Golf','Thogersen','Schechter 2')

late_study = c('ISIS-4')

###Peto analysis function:

library('metafor')

peto_analysis = function(list_of_studies, MgMI_data){
  target_data = MgMI_data[MgMI_data$trialnam %in% list_of_studies,]
  ai = target_data$dead1
  bi = target_data$tot1 - target_data$dead1
  n1i = target_data$tot1
  ci = target_data$dead0
  di = target_data$tot0 - target_data$dead0
  n2i = target_data$tot0
  target_data[, c('trialnam')] = sapply(target_data[, c('trialnam')], as.character)
  slab = target_data$trialnam
  return(rma.peto(ai,bi,ci,di,n1i,n2i, slab = slab, 1, to='none'))
}

###DL analysis function

library(rmeta)

DL_analysis = function(list_of_studies, MgMI_data){
  target_data = MgMI_data[MgMI_data$trialnam %in% list_of_studies,]
  ptrt = target_data$dead1
  ntrt = target_data$tot1
  pctrl = target_data$dead0
  nctrl = target_data$tot0
  statistic = 'OR'
  return(meta.DSL(ntrt, nctrl, ptrt, pctrl, conf.level=0.95, statistic))
}

make_peto_string = function(list_of_studies, MgMI_data){
  peto_results = peto_analysis(list_of_studies, MgMI_data)
  k = peto_results$k
  OR = exp(peto_results$b)
  LB = exp(peto_results$ci.lb)
  UB = exp(peto_results$ci.ub)
  table_string = sprintf("\\multicolumn{5}{l}{Fixed effect (Peto) meta-analysis of above %i trials: OR = %.2f (95 ", k, OR)
  table_string = paste(table_string, "\\% CI: ", sep = "")
  end_string = sprintf("%.2f, %.2f) %s",LB, UB, "} \\\\ \n")
  table_string = paste(table_string, end_string, sep = "")
  return(table_string)
}


make_DL_string = function(list_of_studies, MgMI_data){
  DL_results = DL_analysis(list_of_studies, MgMI_data)
  k = length(DL_results$logs)
  OR = exp(DL_results$logDSL)
  LB = exp(DL_results$logDSL - 1.96*DL_results$selogDSL)
  UB = exp(DL_results$logDSL + 1.96*DL_results$selogDSL)
  table_string = sprintf("\\multicolumn{5}{l}{Random effects (D-L) meta-analysis of above %i trials: OR = %.2f (95 ", k, OR)
  table_string = paste(table_string, "\\% CI: ", sep = "")
  end_string = sprintf("%.2f, %.2f) %s",LB, UB, "} \\\\ \n")
  table_string = paste(table_string, end_string, sep = "")
  return(table_string)
}

writeLines(make_peto_string(early_studies, MgMI))

###Make table

firstdf = MgMI[match(early_studies, MgMI$trialnam),c('trialnam','dead1','tot1','dead0','tot0')]
names(firstdf) = c('Trial', 'Deaths $r_i^M$', 'Patients $n_i^M$', 'Deaths $r_i^C$', 'Patients $n_i^C$')
seconddf = MgMI[match(middle_studies, MgMI$trialnam),c('trialnam','dead1','tot1','dead0','tot0')]
thirddf = MgMI[match(late_study, MgMI$trialnam),c('trialnam','dead1','tot1','dead0','tot0')]

library(xtable)

text_identity = function(x){
  return(x)
}

table = print(xtable(firstdf), include.rownames = FALSE, comment=FALSE, sanitize.text.function = text_identity, table.placement = 'htbp')
table = gsub("\\end{tabular}\n\\end{table}\n","",table,  fixed = TRUE)
table = paste(table, make_peto_string(early_studies, MgMI))
table = paste(table, make_DL_string(early_studies, MgMI))
table = paste(table, print(xtable(seconddf), include.colnames = FALSE, include.rownames = FALSE, only.contents = TRUE, comment=FALSE))
table = paste(table,make_peto_string(c(early_studies, middle_studies), MgMI))
table = paste(table,make_DL_string(c(early_studies, middle_studies), MgMI))
table = paste(table, print(xtable(thirddf), include.colnames = FALSE, include.rownames = FALSE, only.contents = TRUE, comment=FALSE))
table = paste(table,make_peto_string(c(early_studies, middle_studies, late_study), MgMI))
table = paste(table,make_DL_string(c(early_studies, middle_studies, late_study), MgMI))
table = paste(table,"\\end{tabular}\n\\caption{Reproducing Table 2 from Higgens and Spiegelhalter}\n\\label{tab:Table2}\n\\end{table}\n")
table = gsub("table","table*", table)

fileConn = file("tex/table2.tex")
writeLines(table, fileConn)
close(fileConn)

###Make forest plots

par(cex=0.92)
png(filename="./figures/forest_early.png")
forest(peto_analysis(early_studies, MgMI), showweights = TRUE, transf=exp)
grid.text("Forest Plot for First Eight Studies", .5, .85, gp=gpar(cex=2))
grid.text("Study Name                                         Study Weight   Odds Ratio (CI)", .5, .79, gp=gpar(cex=1.2))
dev.off()

png(filename="./figures/forest_middle.png")
forest(peto_analysis(c(early_studies,middle_studies), MgMI), showweights = TRUE,transf=exp)
grid.text("Forest Plot for First 14 Studies", .5, .9, gp=gpar(cex=2))
grid.text("Study Name                                         Study Weight   Odds Ratio (CI)", .5, .84, gp=gpar(cex=1.2))
dev.off()

png(filename="./figures/forest_late.png")
forest(peto_analysis(c(early_studies,middle_studies,late_study), MgMI), showweights = TRUE,transf=exp)
grid.text("Forest Plot for All Studies", .5, .9, gp=gpar(cex=2))
grid.text("Study Name                                          Study Weight   Odds Ratio (CI)", .5, .84, gp=gpar(cex=1.2))
dev.off()

###Bayesian Modeling

library(rstan)

K = nrow(MgMI)
rc = MgMI$dead0
nc = MgMI$tot0
rm = MgMI$dead1
nm = MgMI$tot1


reference_prior = "data {
int<lower=0> K; 			// # trials
real<lower=0> rm[K]; 					// number of treatment deaths
real<lower=0> nm[K]; 					// total number of treatment patients
real<lower=0> rc[K]; 	// number of control deaths
real<lower=0> nc[K]; 	// total number of control deaths
}

transformed data {
real<lower=0> E[K];        // Expected number of treatment deaths
real<lower=0> v[K];                 // Variance of estimate in Peto method
real y[K];                 // Peto effect size estimate
real w[K];                 // Inverse variance of estimate in Peto method
for (n in 1:K){
  E[n] <- (rc[n] + rm[n])/(nc[n] + nm[n]) * nm[n];
  v[n] <- (nc[n]*nm[n]*(rc[n]+rm[n])*(nc[n] + nm[n] - rc[n] -rm[n]))/((nc[n]+nm[n])^2*(nc[n] + nm[n] -1));
  y[n] <- (rm[n] - E[n])/v[n];
  w[n] <- sqrt(1/v[n]); // Recall the normal dist in STAN takes sd as param
  }
}

parameters{
real delta[K];    // Trial-level effect size
real deltanew;          // Average effect size
real<lower=0> tau;         // SD of effect size distribution
}

model { 
//place priors
deltanew ~ normal(0, 100);   // reference prior on deltanew with sd = 100
tau ~ uniform(0,100); // reference prior on tau with sd = 100

//Modeling the data generating process
delta ~ normal(deltanew, tau);     //draw true effect size for each trial (implicit _K)
y ~ normal(delta, w);        //draw a measured effect size with noise
}"

skeptical_prior = "data {
int<lower=0> K; 			// # trials
real<lower=0> rm[K]; 					// number of treatment deaths
real<lower=0> nm[K]; 					// total number of treatment patients
real<lower=0> rc[K]; 	// number of control deaths
real<lower=0> nc[K]; 	// total number of control deaths
}

transformed data {
real<lower=0> E[K];        // Expected number of treatment deaths
real<lower=0> v[K];                 // Variance of estimate in Peto method
real y[K];                 // Peto effect size estimate
real w[K];                 // Inverse variance of estimate in Peto method
for (n in 1:K){
E[n] <- (rc[n] + rm[n])/(nc[n] + nm[n]) * nm[n];
v[n] <- (nc[n]*nm[n]*(rc[n]+rm[n])*(nc[n] + nm[n] - rc[n] -rm[n]))/((nc[n]+nm[n])^2*(nc[n] + nm[n] -1));
y[n] <- (rm[n] - E[n])/v[n];
w[n] <- sqrt(1/v[n]); // Recall the normal dist in STAN takes sd as param
}
}

parameters{
real delta[K];    // Trial-level effect size
real deltanew;          // Average effect size
real<lower=0> tau;         // SD of effect size distribution
}

model { 
//place priors
deltanew ~ normal(0, sqrt(0.03));   // skeptical prior on deltanew with var = 0.03
tau ~ uniform(0,100); // reference prior on tau with sd = 100

//Modeling the data generating process
delta ~ normal(deltanew, tau);     //draw true effect size for each trial (implicit _K)
y ~ normal(delta, w);        //draw a measured effect size with noise
}"

library(ggplot2)

##Fit skeptical prior and create plots
fit_skeptical_prior = stan(model_code = skeptical_prior, data = c("K", "rm", "nm",'rc','nc'), pars = c("deltanew"), iter = 500000, chains = 3)
skeptical_prior_return_vals <- extract(fit_skeptical_prior, permuted=TRUE)
png(filename="./figures/skeptical_hist.png")
hist(exp(skeptical_prior_return_vals$deltanew), breaks=100, xlim =c(0,1.4), xlab = expression(exp(delta[new])), main=expression("Distribution of" ~ exp(delta[new]) ~ "under skeptical prior"))
dev.off()
png(filename="./figures/skeptical_trace.png")
traceplot(fit_skeptical_prior, pars= "deltanew") + labs(y = expression(delta[new]), title = expression("Trace plot for" ~ delta[new] ~ "under skeptical prior"))
dev.off()

##Fit reference prior and create plots
fit_reference_prior = stan(model_code = reference_prior, data = c("K", "rm", "nm",'rc','nc'), pars = c("deltanew"), iter = 500000, chains = 3)
reference_prior_return_vals <- extract (fit_reference_prior, permuted=TRUE)
png(filename="./figures/reference_hist.png")
hist(exp(reference_prior_return_vals$deltanew), breaks=100, xlim =c(0,1.4),xlab = expression(exp(delta[new])), main=expression("Distribution of" ~ exp(delta[new]) ~ "under reference prior"))
dev.off()
png(filename="./figures/reference_trace.png")
traceplot(fit_reference_prior, pars= "deltanew") + labs(y = expression(delta[new]), title = expression("Trace plot for" ~ delta[new] ~ "under reference prior"))
dev.off()

##Get point estimate and CI for delta_new

summary_reference = summary(fit_reference_prior, digits = 3)
summary_skeptical = summary(fit_skeptical_prior, digits = 3)

get_ci = function(summary_from_stan){
  point_est = exp(summary_from_stan$summary['deltanew','mean'])
  lb_ci = exp(summary_from_stan$summary['deltanew','2.5%'])
  ub_ci = exp(summary_from_stan$summary['deltanew','97.5%'])
  return(c('Posterior mean $\\exp(\\delta_{new})$' = point_est,'Lower bound (95% CI)'=lb_ci,'Upper bound (95% CI)'=ub_ci))
}
summary_table = as.data.frame(list('Reference' = get_ci(summary_reference),'Skeptical' =get_ci(summary_skeptical)))
summary_table = print(xtable(summary_table, caption='Posterior distribution mean and 95\\% confidence interval',label='tab:sum_post_dist'), include.rownames = TRUE, comment=FALSE, sanitize.text.function = text_identity, table.placement = 'htbp')
fileConn = file("tex/table3.tex")
writeLines(summary_table, fileConn)
close(fileConn)

get_clinical_stats_sig = function(stan_return_vals){
  num_iters = length(stan_return_vals$deltanew)
  tot_stats_sig = sum(stan_return_vals$deltanew > 0)
  tot_clin_sig = sum(stan_return_vals$deltanew > log(0.9))
  return(c('P($\\exp(\\delta_{new}) < 1$)'= tot_stats_sig/num_iters, 'P($\\exp(\\delta_{new}) < 0.9$)'= tot_clin_sig/num_iters))
}

summary_table = as.data.frame(list('Reference' = get_clinical_stats_sig(reference_prior_return_vals),'Skeptical' =get_clinical_stats_sig(skeptical_prior_return_vals)))
summary_table = print(xtable(summary_table, caption='Probabilities of clinical and statistical significance under priors',label='tab:prob_sigs', digits=4), include.rownames = TRUE, comment=FALSE, sanitize.text.function = text_identity, table.placement = 'htbp')
fileConn = file("tex/table4.tex")
writeLines(summary_table, fileConn)
close(fileConn)
