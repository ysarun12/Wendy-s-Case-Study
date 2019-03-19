LIBNAME Project 'C:\Users\Arun\Desktop\UT Dallas\Predictive Analytics with SAS\Project'; run;

/*CLUSTERING SUMMARY*/
***********************;

proc import datafile = 'C:\Users\Arun\Desktop\UT Dallas\Predictive Analytics with SAS\Project\LCAforBox.csv'
dbms = csv
out = Project.Input;
run;

*Cluster size by customers/
**************************;
proc freq data = Project.Input;
table modal/ out = Project.cluster_size;
run;

proc export data = Project.cluster_size outfile = 'C:\Users\Arun\Desktop\UT Dallas\Predictive Analytics with SAS\Project\Cluster summary.csv'
dbms = csv replace;
run;

*Cluster size by revenue/
**************************;

proc sort data = Project.Input;
by customerid;
run;

proc sort data = Project.jas;
by customerid;
run;

data Project.for_revenue; 
merge Project.Input (in = a) project.jas (in = b keep = paper_ns pct_ns sew_ns needle_ns quilt_ns impulse_ns other_ns kids_ns ribbon_ns paint_ns celeb_ns
 public_ns bccomp_ns);  
run;

data Project.for_revenue2;
set Project.for_revenue;
tot_revenue = paper_ns +pct_ns +sew_ns +needle_ns +quilt_ns +impulse_ns +other_ns +kids_ns +ribbon_ns +paint_ns +celeb_ns
 +public_ns +bccomp_ns;
run;

proc means data = Project.for_revenue2 noprint;
class modal;
var tot_revenue;
output out = Project.cluster_rev (drop = _type_ _freq_) sum(tot_revenue) = rev_sum;
run;

proc export data = Project.Cluster_rev outfile = 'C:\Users\Arun\Desktop\UT Dallas\Predictive Analytics with SAS\Project\Cluster revenue.csv'
dbms = csv replace;
run;

data for_summary;
set Project.Input;
drop customerid cluster:;
run;
 
proc means data = for_summary noprint;
class modal;
/*var tot_revenue;*/
output out = Project.cluster_summary (drop = _type_ _freq_) mean = ;
run;


/*keep only required variables*/

proc contents data = project.jas out = project.var_names noprint;
run;

proc sql;
select name into: for_delete separated by ' ' from project.var_names
where name like '%^_ns' escape '^' or name like '%^_ns_qty' escape '^';
quit;

*%put &for_delete.;

data project.clus1;
set project.jas;
drop &for_delete. allcom_cnt;
run; 

*Standardize the variables before clustering;

proc standard data = project.clus1 mean = 0 std = 1 out = project.std_jas;
run;

data project.std_jas2;
set project.std_jas;
array variables _numeric_;
do i = 1 to dim(variables);
	if variables(i) > 3 or variables(i) < -3 then delete;
end;
run;

*K-means;

proc fastclus data = project.std_jas2 
maxclusters = 5 out = project.clustered_results ;
var _numeric_;
run;

*Take the non-standardized dataset and retain the customer ids left after deleting outliers;

proc sql;
create table project.clustered_results2 as
select a.*, b.cluster from project.clus1 a
inner join project.clustered_results b on
a.customerid = b.customerid;
quit;

/*Generate cluster means*/

proc means data = project.clustered_results2 noprint;
var _numeric_ ;
class cluster;
output out = project.cluster_means (drop = _type_ _freq_);
run;

proc export data = project.cluster_means
outfile = "C:\Users\Arun\Desktop\UT Dallas\Predictive Analytics with SAS\Project\Cluster Means.csv"
dbms = csv;
run;




