%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% This script create variables containing netCDF information.
%

% Set main path
if strcmp(machine,'sciserver')
    if strcmp(expname,'exp_ASR')
        infonc.mainpath = '/home/idies/workspace/OceanCirculation/exp_ASR/';
    elseif strcmp(expname,'exp_ERAI')
        infonc.mainpath = '/home/idies/workspace/OceanCirculation/exp_ERAI/';
    end
elseif strcmp(machine,'datascope')
    if strcmp(expname,'exp_ASR')
        infonc.mainpath = '/datascope/hainegroup/malmans2/exp_ASR/';
    elseif strcmp(expname,'exp_ERAI')
        infonc.mainpath = '/export/scratch/malmans2/exp_ERAI/';
    elseif strcmp(expname,'exp_ERAI-monthly')
	infonc.mainpath = '/datascope/hainegroup/malmans2/exp_ASR-monthly/';
    elseif strcmp(expname,'exp_ERAI-renske')
	infonc.mainpath = '/datascope/hainegroup/malmans2/exp_ERAI-renske/';
    end
else
    error('Error.\nMachine %s NOT available',machine);
end
    
% Set gridpath
infonc.gridpath = [infonc.mainpath 'grid_glued.nc'];

% Set reference time
infonc.reftime = datenum('01-Jan-2007 00','dd-mmm-yyyy HH');

% Set time step
infonc.deltaT = 0.25; % days

% Parameters
infonc.rho0 = 1027;
infonc.c_p = 3986;

% Read variable information
txtname = [toolspath 'info/info_' expname '.txt'];
[N,CLASS,NAME,DESCRIPTION,UNITS,DIRECTORY] = textread(txtname,'%s %s %s %s %s %s','delimiter','|');
infonc.vars.N           = strtrim(N(3:end));
infonc.vars.CLASS       = strtrim(CLASS(3:end));
infonc.vars.NAME        = strtrim(NAME(3:end));
infonc.vars.DESCRIPTION = strtrim(DESCRIPTION(3:end));
infonc.vars.UNITS       = strtrim(UNITS(3:end));
infonc.vars.DIRECTORY   = strtrim(DIRECTORY(3:end));
infonc.vars.CROPPED     = {'ADVr_TH'; 
			   'ADVx_TH'; 
			   'ADVy_TH'; 
			   'ADVr_SLT'; 
			   'ADVx_SLT';
			   'ADVy_SLT'; 
			   'DFrI_TH'; 
		           'DFrI_SLT'; 
	                   'TFLUX';
	                   'SFLUX';
	 		   'KPPg_TH';
	 		   'KPPg_SLT'; 
			   'oceQsw_AVG';
			   'oceSPtnd'};
clear N CLASS NAME DESCRIPTION UNITS DIRECTORY

% List all directories
listdirs = dir([infonc.mainpath 'result*']);
for i = 1:length(listdirs)
	infonc.dirs.NAME{i}     = listdirs(i).name;
	infonc.dirs.FIRSTDAY{i} = datenum(listdirs(i).name(8:15),'yyyymmdd')+1.00;
	infonc.dirs.LASTDAY{i}  = datenum(listdirs(i).name(17:end),'yyyymmdd')-1.25;
end

% Fix cropped lag
infonc.dirs.FIRSTDAYcropped = infonc.dirs.FIRSTDAY;
infonc.dirs.LASTDAYcropped  = infonc.dirs.LASTDAY;
ind1 = find([infonc.dirs.FIRSTDAYcropped{:}]==datenum('11-Nov-2007 00','dd-mmm-yyyy HH'));
ind2 = find([infonc.dirs.FIRSTDAYcropped{:}]==datenum('01-Mar-2008 00','dd-mmm-yyyy HH'));
for ind=ind1:ind2
	infonc.dirs.FIRSTDAYcropped{ind} = infonc.dirs.FIRSTDAYcropped{ind}+infonc.deltaT;
end
for ind=ind1-1:ind2-1
        infonc.dirs.LASTDAYcropped{ind} = infonc.dirs.LASTDAYcropped{ind}+infonc.deltaT;
end
infonc.dirs.FIRSTDAYcropped{1} = infonc.dirs.FIRSTDAYcropped{1}+infonc.deltaT;

