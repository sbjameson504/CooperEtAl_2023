options ls=100 ps=72;
data one;
infile 'C:\Path\to\csv\XXXXXXXX.csv' delimiter=',' end=last dsd missover firstobs=2;
*(use special Excel file with only one Z between probes. don't use this output for waveform Z durations if you have 2 z names!);
*ensure variables for analysis are listed on the lines below
length insectno waveform$ 8 dur 8 cur$ 1 ri$ 1;
input insectno waveform$ dur cur$ ri$;

if waveform='np' or waveform='NP' or waveform='nP' or waveform='Np' then waveform='Z';
if waveform='z' then waveform='Z';

*status=1;
*tbf=1;
Data one; Set one;
waveform=compress(upcase(waveform));
ods graphics on;

*ODS noresults; *suppresses output to "results" and "output" windows.;
*ODS HTML file='C:\saswork\Rosana output' ; *Directs all output to this file.;


retain sum 0;

data one; set one;
retain seq2 seq3 seq1 w0 w1 in0 np0  p0 np1 p1;


w1=substr(waveform,1,1);
if w1 ne 'Z' then w1='S';
if insectno ne in0 then do;
 np0=0; p0=0;
 np1=0;p1=0;
 seq3=0;
 in0=insectno;
 w0='';
end;
   if w1='Z' then do;
     np1=np1+1;
     seq1=np1;
   end;
   else do;
     p1=p1+1;
     seq1=p1;
   end;
if w1 ne w0 then do;
   seq3=0;
   if w1='Z' then do;
     np0=np0+1;
     seq2=np0;
   end;
   *else do;
     *p0=p0+1;
     *seq2=p0;
   *end;
  w0=w1;
end;
seq3=seq3+1;
keep insectno cur ri waveform dur seq1 seq2 seq3 ;


data one; set one;
*if tbf > 3600 then delete; *(hour 1 only);
*if tbf < 3600 then delete; *(hour 2 only);
*if tbf > 7200 then delete; *(hour 2 only);
*if tbf > 10800 then delete; *(hour 3 only);
*if tbf > 14400 then delete; *(hour 4 only);
*proc print;
*var insectno waveform trt dur seq1 seq2 seq3 ;
*title 'Complete data set- incl. Z';

*if tbf > 3600 then delete; *(hour 1 only);
*if tbf < 3600 then delete; *(hour 2 only);
*if tbf > 7200 then delete; *(hour 2 only);
*if tbf > 10800 then delete; *(hour 3 only);
*if tbf > 14400 then delete; *(hour 4 only);

data two; set one;
probe='yes';
if waveform='Z' then probe='no';
if probe='yes' then delete;
*proc print;
*var insectno trt status waveform tbf dur seq1 seq2 seq3 ;
*title 'Complete data set - Z only';
run;
data two; set one;
*if tbf > 3600 then delete; *(hour 1 only);
*if tbf < 3600 then delete; *(hour 1 only);
*if tbf > 7200 then delete; *(hour 2 only);
*if tbf > 10800 then delete; *(hour 3 only);
*if tbf > 14400 then delete; *(hour 4 only);

Data Original1; set one;
Data Original2; set two;

***************************** This finishes the pre-processing step  *******************************;
****************************** START COHORT EVENT LEVEL VARIABLES  ********************************;
data one; set one;
proc sort; by waveform cur ri;
proc means n sum mean stderr min max; by waveform cur ri;
var dur;
title 'Eq. 33 (WDE) (mean, std. error), Eq. 22 (TWD) (sum) and Eq. 26 (TNWE) (N) for probe = yes';

data one; set one;
ldur= log10(dur);
proc sort; by waveform cur ri;

*This is an example of the code for 2-factor proc glimmix with interaction (to remove interaction remove the 'cur*ri' term in the model statement)
*Ensure both variables of interest are in the class and model statements
*The lsmeans statements can only take one variable at a time, but you can run it twice to see both variables
proc glimmix plots=residualpanel; by waveform; 
class cur ri;
model dur=cur ri cur*ri;
lsmeans cur/pdiff lines;
lsmeans ri/pdiff lines;
title1 'ANOVA & LSD of WDE (not transformed)';
title2 'By no. of insects performing behavior';

proc sort; by waveform cur ri;
proc glimmix plots=residualpanel; by waveform; 
class cur ri;
model ldur=cur ri cur*ri;
lsmeans cur/pdiff lines;
lsmeans ri/pdiff lines;
title1 'ANOVA & LSD of WDE (log transformed)';
title2 'By no. of insects performing behavior';

ods html close;
ods graphics off;
run;
quit;
