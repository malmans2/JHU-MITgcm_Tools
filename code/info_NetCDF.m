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
infonc.c_p  = 3986;

% Read variable information
txtname = [toolspath 'info/info_' expname '.txt'];
[N,CLASS,NAME,DESCRIPTION,UNITS,DIRECTORY] = textread(txtname,'%s %s %s %s %s %s','delimiter','|');
infonc.vars.N           = strtrim(N(3:end));
infonc.vars.CLASS       = strtrim(CLASS(3:end));
infonc.vars.NAME        = strtrim(NAME(3:end));
infonc.vars.DESCRIPTION = strtrim(DESCRIPTION(3:end));
infonc.vars.UNITS       = strtrim(UNITS(3:end));
infonc.vars.DIRECTORY   = strtrim(DIRECTORY(3:end));
clear N CLASS NAME DESCRIPTION UNITS DIRECTORY

% List all directories
listdirs = dir([infonc.mainpath 'result*']);
for i = 1:length(listdirs)
	infonc.dirs.NAME{i}     = listdirs(i).name;
	infonc.dirs.FIRSTDAY{i} = datenum(listdirs(i).name(8:15),'yyyymmdd')+1.00;
	infonc.dirs.LASTDAY{i}  = datenum(listdirs(i).name(17:end),'yyyymmdd')-1.25;
end


