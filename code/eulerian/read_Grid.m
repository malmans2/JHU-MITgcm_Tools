function [grid] = read_Grid
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Get grid information.
% This function doesn't require any input.
% Indeed, global variables are called by set_globalvars
%
% OUTPUT:
%	grid: structure array containing grid informations.
	
	% Set global variables and start timing
	tic
	run set_globalvars
	fprintf(logID,'\n Reading grid variables:');
	
	% Read variables
	gridinfo = ncinfo(infonc.gridpath);
	for i = 1:length(gridinfo.Variables)
        	thisvar = gridinfo.Variables(i).Name;
        	grid.(thisvar) = ncread(infonc.gridpath,thisvar);

        	% Remove 0s in coordinates due to exch2
        	switch thisvar
                	case {'XC','XG','XU','XV'}
                        	tmp = grid.(thisvar);
                        	tmp(tmp==0) = NaN;
                        	tmp = nanmean(tmp,2);
                        	grid.(lower(thisvar)) = tmp;
                	case {'YC','YG','YU','YV'}
                        	tmp = grid.(thisvar);
                        	tmp(tmp==0) = NaN;
                        	tmp = nanmean(tmp,1);
                        	grid.(lower(thisvar)) = tmp;
        	end
        	clear thisvar tmp
	end
	% Timing
        fprintf(logID,' done in %f seconds\n',toc);

end
