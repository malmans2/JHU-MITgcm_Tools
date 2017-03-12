function [figgrid] = plot_Grid(savefig)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Plot the numerical domain superimposed on seafloor bathymetry.
% Red lines bound the high resolution area.
% Global variables are called by set_globalvars
%
% INPUT:
%	savefig: leave it empty if you don't want to save the figure.
%		      If 'filename' is provided, it prints the figure to filename.eps
%
% OUTPUT:
%	figgrid: it is the handle to the figure object
%

	% Set global variables 
        run set_globalvars

	% Check inputs
	if ~isempty(savefig) & ~ischar(savefig)
        	error('Error.\nLeave savefig empty if you do not want to save the figure. Otherwise, provide a string',1)
   	end

	% Initialize plot
	figgrid = figure('PaperPosition',[.25 .25 8 6]);
	hold on
	axis off
	axesm(  'MapProjection','mercator',...
        	'MapLatLimit',[min(grid.yg) max(grid.yg)],...
        	'MapLonLimit',[min(grid.xg) max(grid.xg)],...
        	'Frame','on',...
        	'FFill',0,...
        	'FEdgeColor',[0 0 0],...
        	'FFaceColor',[253 180 108]/255,...
        	'Grid','on',...
        	'MLineLocation',grid.xg(1:40:end),...
        	'PLineLocation',grid.yg(1:44:end),...
        	'GColor',[0 0 0],...
        	'GLineStyle',':',...
        	'GLineWidth',0.5,...
        	'FontSize',15,...
        	'FontWeight','bold',...
        	'LabelFormat','signed',...
        	'MeridianLabel','on',...
        	'MLabelLocation',10,...
        	'ParallelLabel','on',...
        	'PLabelLocation',5);

	% Plot bathymetry
	grid.Depth(grid.Depth<=0)=NaN;
	pcolorm(grid.yc,grid.xc,grid.Depth')
	colormap(figgrid,flipud(bone));
	cbar = colorbar();
	cbar.Label.String = 'Depth [m]';
	
	% Define high resolution area
	ind1 = min(find(diff(round(diff(grid.xg),4))==0));
	ind2 = max(find(diff(round(diff(grid.xg),4))==0))+2;
	ind3 = min(find(diff(round(diff(grid.yg),4))==0));
	ind4 = max(find(diff(round(diff(grid.yg),4))==0))+2;

	% Plot high resolution area
	lWidth = 3;
	plotm([grid.yg(ind3) grid.yg(ind3)],[grid.xg(ind1) grid.xg(ind2)],'r-o','Linewidth',lWidth,'MarkerSize',lWidth);
	plotm([grid.yg(ind4) grid.yg(ind4)],[grid.xg(ind1) grid.xg(ind2)],'r-o','Linewidth',lWidth,'MarkerSize',lWidth);
	plotm([grid.yg(ind3) grid.yg(ind4)],[grid.xg(ind1) grid.xg(ind1)],'r-o','Linewidth',lWidth,'MarkerSize',lWidth);
	plotm([grid.yg(ind3) grid.yg(ind4)],[grid.xg(ind2) grid.xg(ind2)],'r-o','Linewidth',lWidth,'MarkerSize',lWidth);

	% Write comments and colorbar
	textm(74,-42,'Greenland','FontSize',15,'FontWeight','bold');
	textm(65,-22,'Iceland','FontSize',12,'FontWeight','bold');
	textm(70,-41,'2km resolution','FontSize',15,'FontWeight','bold','Color','r');

	if ~isempty(savefig)
		% Save figure
		fprintf(logID,'\n Saving grid figure to [%s.eps]:',savefig);
		tic
		print(savefig,'-depsc2','-r300');
		fprintf(logID,' done in %f seconds\n',toc);
	end

