function plot_VerticalSection(Fields,VERTSECS,plotmean,savemovie)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
% Plot Vertical Section
% This function also work with "moorings", "horizontal section" and "One-depth stations"
%
% INPUT:
%       Fields:     cell array containing fields' names
%                   e.g. Fields = {'Temp' 'S' 'U' ...}
%	VERSECS:    structure array containg vertical section info.
%		    VERTSECS is obtained with create_VerticalSection
%       plotmean:   0: don't plot the mean vertica sections
%                   1: plot the mean vertical sections
%                   'filename': save requested vertical sections to filename_Field.eps
%       savemovie:  Leave it empty if you don't want to save movies (loop over time). 
%                   If 'filename' is provided, filename_Field.mat will be saved
%

	

	% Set global variables 
        run set_globalvars
	
	% Read variables
	for f=1:length(Fields)
		fieldname = Fields{f};
		LON       = VERTSECS.(fieldname).('LON');
		LAT       = VERTSECS.(fieldname).('LAT');
		DIST      = VERTSECS.(fieldname).('DIST');
		DEPTH     = VERTSECS.(fieldname).('DEPTH');
		TIME      = VERTSECS.(fieldname).('TIME');
		units     = VERTSECS.(fieldname).('units');
		long_name = VERTSECS.(fieldname).('long_name');
		bathy     = VERTSECS.(fieldname).('bathy');
		field     = VERTSECS.(fieldname).('values');
		if length(DIST)>2 & length(DEPTH)>2
			% VERTICAL SECTION
			if plotmean~=0 
				% Create mean field
				meanfld = nanmean(VERTSECS.(fieldname).('values'),3);
				
				% Figure
				meanfig.(fieldname) = figure('visible','off','PaperPosition',[.25 .25 8 6]);
				hold on
                        	set(gca,'YDir','Reverse')
                        	title(long_name,'Interpreter','none')
				xlim([min(DIST) max(DIST)])
				ylim([min(DEPTH) max(DEPTH)])
				cbar = colorbar();
                        	caxis([nanmin(meanfld(:)) nanmax(meanfld(:))]);
                        	cbar.Label.String = units;
				ylabel('Depth [m]')
				if LON(1)<LON(end)
					xlabel('Distance from the westernmost point')
				elseif LON(1)>LON(end)
					xlabel('Distance from the easternmost point')
				elseif LAT(1)<LAT(end)
					xlabel('Distance from the southernmost point')
				elseif LAT(1)>LAT(end)
					xlabel('Distance from the northern point')
				end
			
				% Find bathymetry
				bathy(isnan(bathy)) = 0;
                        	x1 = DIST(~isnan(bathy));
                        	x1 = reshape(x1,1,length(x1));
                        	y1 = bathy(~isnan(bathy));
                        	y1 = reshape(y1,1,length(y1));
                        	x2 = x1;
                        	y2 = repmat(max(y1)+100,size(x2));
                        	
				% Plot field
				h1 = pcolor(DIST,DEPTH,meanfld');
				shading flat

				% Plot bathymetry
				landcol = [0.4 0.4 0.4];
                        	h2 = fill([x1,fliplr(x2)],[y1,fliplr(y2)],landcol,'edgecolor',landcol);
                        	h3 = plot(x1,y1,'k-','LineWidth',3);
			
				if ischar(plotmean)
                        		% Save figure
                        		filename = [plotmean '_' fieldname];
                        		fprintf(logID,'\n Saving mean [%s] vertical section to [%s.eps]:',fieldname,filename);
                        		tic
                        		print(filename,'-depsc2','-r300');
                        		fprintf(logID,' done in %f seconds\n',toc);
                		end
			end
			if ~isempty(savemovie)
				% Initialize progress
                		perc = 0:10:100;
                		filename = [savemovie '_' fieldname '.gif'];
                		fprintf(logID,'\n Saving [%s] vertical section movie to [%s]:\n     Progress:',fieldname,filename);
                		tic
				
				% Figure
                                moviefig = figure('visible','off');
                                set(moviefig,'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); 
                                hold on
                                set(gca,'YDir','Reverse')
                                xlim([min(DIST) max(DIST)])
                                ylim([min(DEPTH) max(DEPTH)])
                                cbar = colorbar();
                                caxis([nanmin(field(:)) nanmax(field(:))]);
                                cbar.Label.String = units;
                                ylabel('Depth [m]')
                                if LON(1)<LON(end)
                                        xlabel('Distance from the westernmost point')
                                elseif LON(1)>LON(end)
                                        xlabel('Distance from the easternmost point')
                                elseif LAT(1)<LAT(end)
                                        xlabel('Distance from the southernmost point')
                                elseif LAT(1)>LAT(end)
                                        xlabel('Distance from the northern point')
                                end

                                % Find bathymetry
                                bathy(isnan(bathy)) = 0;
                                x1 = DIST(~isnan(bathy));
                                x1 = reshape(x1,1,length(x1));
                                y1 = bathy(~isnan(bathy));
                                y1 = reshape(y1,1,length(y1));
                                x2 = x1;
                                y2 = repmat(max(y1)+100,size(x2));

				% Createmovie
				for t=1:length(TIME)
					fld = field(:,:,t);
					% Title
					title({long_name datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
					% Plot field
                                	h1 = pcolor(DIST,DEPTH,fld');
                                	shading flat

                                	% Plot bathymetry
                                	landcol = [0.4 0.4 0.4];
                                	h2 = fill([x1,fliplr(x2)],[y1,fliplr(y2)],landcol,'edgecolor',landcol);
                                	h3 = plot(x1,y1,'k-','LineWidth',3);

                        		% Create movie
					frame = getframe(moviefig);
                        		MOVIE(t) = frame;

                                	% Clear plot
                                	reset(h1)
                                	reset(h2)
                                	reset(h3)

                        		% Save gif
                        		im = frame2im(frame);
                        		[imind,cm] = rgb2ind(im,256);
                        		if t==1
                                		imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
                        		else
                                		imwrite(imind,cm,filename,'gif','WriteMode','append');
                        		end

                        		% Show progress
                        		thisperc = ceil(t*10/length(TIME))*10;
                        		if any(thisperc==perc)
                                		fprintf(logID,'  [%d]',thisperc);
                                		perc(perc==thisperc) = [];
                        		end
				end
                % Close figure
                close(moviefig)
				fprintf(logID,'\n Movie created in %f seconds\n',toc);
			end
		elseif length(DIST)<2 & length(DEPTH)>2 
			% MOORING
			if plotmean~=0
				% Create mean field
                                meanfld = nanmean(VERTSECS.(fieldname).('values'),3);

                                % Figure
                                meanfig.(fieldname) = figure('visible','off','PaperPosition',[.25 .25 8 6]);
				hold on
                                set(gca,'YDir','Reverse')
                                title({long_name [num2str(LAT) 'degN ; ' num2str(LON) 'degE']},'Interpreter','none')
				
                                xlim([nanmin(meanfld(:)) nanmax(meanfld(:))])
                                ylim([min(DEPTH) max(DEPTH)])
                                xlabel(units);
                                ylabel('Depth [m]')

				% Plot field
				lWidth = 2;
				mSize  = 3;
                                h1 = plot(meanfld(~isnan(meanfld)),DEPTH(~isnan(meanfld)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);

				if ischar(plotmean)
                                        % Save figure
                                        filename = [plotmean '_' fieldname];
                                        fprintf(logID,'\n Saving mean [%s] vertical profile to [%s.eps]:',fieldname,filename);
                                        tic
                                        print(filename,'-depsc2','-r300');
                                        fprintf(logID,' done in %f seconds\n',toc);
                                end
			end
			if ~isempty(savemovie)
                                % Initialize progress
                                perc = 0:10:100;
                                filename = [savemovie '_' fieldname '.gif'];
                                fprintf(logID,'\n Saving [%s] vertical section movie to [%s]:\n     Progress:',fieldname,filename);
                                tic

				% Figure
                                moviefig = figure('visible','off');
                                set(moviefig,'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); 
                                hold on
                                set(gca,'YDir','Reverse')
                                xlim([nanmin(field(:)) nanmax(field(:))])
                                ylim([min(DEPTH) max(DEPTH)])
                                xlabel(units);
                                ylabel('Depth [m]')

				% Createmovie
                                for t=1:length(TIME)
                                        fld = field(:,:,t);
					% title
					title({long_name [num2str(LAT) 'degN ; ' num2str(LON) 'degE'] datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
                                        % Plot field
                                	lWidth = 2;
                                	mSize  = 3;
                                	h1 = plot(fld(~isnan(fld)),DEPTH(~isnan(fld)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);

                                        % Create movie
                                        frame = getframe(moviefig);
                                        MOVIE(t) = frame;
					
                                        % Clear plot
                                        reset(h1)

                                        % Save gif
                                        im = frame2im(frame);
                                        [imind,cm] = rgb2ind(im,256);
                                        if t==1
                                                imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
                                        else
                                                imwrite(imind,cm,filename,'gif','WriteMode','append');
                                        end

                                        % Show progress
                                        thisperc = ceil(t*10/length(TIME))*10;
                                        if any(thisperc==perc)
                                                fprintf(logID,'  [%d]',thisperc);
                                                perc(perc==thisperc) = [];
                                        end
                                end
                                % Close figure
                                close(moviefig)
                                fprintf(logID,'\n Movie created in %f seconds\n',toc);
			end
			
		elseif length(DIST)>2 & length(DEPTH)<2
			% 1Depth transect
                        if plotmean~=0
                                % Create mean field
                                meanfld = nanmean(VERTSECS.(fieldname).('values'),3);

                                % Figure
                                meanfig.(fieldname) = figure('visible','off','PaperPosition',[.25 .25 8 6]);
                                hold on
				if ~isempty(DEPTH)
                                	title({long_name ['Depth=' num2str(DEPTH) 'm']},'Interpreter','none')
				else
					title(long_name,'Interpreter','none')
				end
                                ylim([nanmin(meanfld(:)) nanmax(meanfld(:))])
                                xlim([min(DIST) max(DIST)])
                                ylabel(units);
                                if LON(1)<LON(end)
                                        xlabel('Distance from the westernmost point')
                                elseif LON(1)>LON(end)
                                        xlabel('Distance from the easternmost point')
                                elseif LAT(1)<LAT(end)
                                        xlabel('Distance from the southernmost point')
                                elseif LAT(1)>LAT(end)
                                        xlabel('Distance from the northern point')
                                end


                                % Plot field
                                lWidth = 2;
                                mSize  = 3;
                                h1 = plot(DIST(~isnan(meanfld)),meanfld(~isnan(meanfld)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);

                                if ischar(plotmean)
                                        % Save figure
                                        filename = [plotmean '_' fieldname];
                                        fprintf(logID,'\n Saving mean [%s] horizontal profile to [%s.eps]:',fieldname,filename);
                                        tic
                                        print(filename,'-depsc2','-r300');
                                        fprintf(logID,' done in %f seconds\n',toc);
                                end
                        end
			if ~isempty(savemovie)
                                % Initialize progress
                                perc = 0:10:100;
                                filename = [savemovie '_' fieldname '.gif'];
                                fprintf(logID,'\n Saving [%s] horizontal section movie to [%s]:\n     Progress:',fieldname,filename);
                                tic

                                % Figure
                                moviefig = figure('visible','off');
                                set(moviefig,'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); 
                                hold on
                                if ~isempty(DEPTH)
                                        title({long_name ['Depth=' num2str(DEPTH) 'm']},'Interpreter','none')
                                else
                                        title(long_name,'Interpreter','none')
                                end
                                ylim([nanmin(field(:)) nanmax(field(:))])
                                xlim([min(DIST) max(DIST)])
                                ylabel(units);
                                if LON(1)<LON(end)
                                        xlabel('Distance from the westernmost point')
                                elseif LON(1)>LON(end)
                                        xlabel('Distance from the easternmost point')
                                elseif LAT(1)<LAT(end)
                                        xlabel('Distance from the southernmost point')
                                elseif LAT(1)>LAT(end)
                                        xlabel('Distance from the northern point')
                                end

                                % Createmovie
                                for t=1:length(TIME)
                                        fld = field(:,:,t);
                                        % title
					if ~isempty(DEPTH)
                                        	title({long_name ['Depth=' num2str(DEPTH) 'm'] datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
                                	else
                                        	title({long_name datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
                               	 	end
                                        % Plot field
                                        lWidth = 2;
                                        mSize  = 3;
                                        h1 = plot(DIST(~isnan(fld)),fld(~isnan(fld)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);

                                        % Create movie
                                        frame = getframe(moviefig);
                                        MOVIE(t) = frame;

                                        % Clear plot
                                        reset(h1)

                                        % Save gif
                                        im = frame2im(frame);
                                        [imind,cm] = rgb2ind(im,256);
                                        if t==1
                                                imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
                                        else
                                                imwrite(imind,cm,filename,'gif','WriteMode','append');
                                        end

                                        % Show progress
                                        thisperc = ceil(t*10/length(TIME))*10;
                                        if any(thisperc==perc)
                                                fprintf(logID,'  [%d]',thisperc);
                                                perc(perc==thisperc) = [];
                                        end
                                end
                                % Close figure
                                close(moviefig)
                                fprintf(logID,'\n Movie created in %f seconds\n',toc);
                        end


		else
			% 1Depth Station
			if plotmean~=0 | ~isempty(savemovie)
				% Figure 
				meanfig.(fieldname) = figure('visible','off','PaperPosition',[.25 .25 8 6]);
				hold on
                                ylim([nanmin(field) nanmax(field)])
                                ylabel(units)
				if ~isempty(DEPTH)
					title({long_name [num2str(LAT) 'degN ; ' num2str(LON) 'degE']},'Interpreter','none')
				else
					title({long_name [num2str(LAT) 'degN ; ' num2str(LON) 'degE'] ['Depth=' num2str(DEPTH) 'm']},'Interpreter','none')
				end
				% Plot
				lWidth = 2;
                                mSize  = 3;
				field  = squeeze(field);
                                h1 = plot(TIME(~isnan(field)),field(~isnan(field)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);
				h2 = plot(TIME,repmat(nanmean(field),size(TIME)),'r--','LineWidth',lWidth,'MarkerSize',mSize);
				datetick('x','dd/mm/yy')
				xlim([nanmin(TIME(:)) nanmax(TIME(:))])
				legend([h1,h2],'timeseries','mean','Location','best')

				if ischar(plotmean)
                                        % Save figure
                                        filename = [plotmean '_' fieldname];
                                        fprintf(logID,'\n Saving [%s] timeseries to [%s.eps]:',fieldname,filename);
                                        tic
                                        print(filename,'-depsc2','-r300');
                                        fprintf(logID,' done in %f seconds\n',toc);
                                end

				if ~isempty(savemovie)
                                        % Save figure
                                        filename = [savemovie '_' fieldname];
                                        fprintf(logID,'\n Saving [%s] timeseries to [%s.eps]:',fieldname,filename);
                                        tic
                                        print(filename,'-depsc2','-r300');
                                        fprintf(logID,' done in %f seconds\n',toc);
                                end
			end
		end

	end
	
	if plotmean~=0
		for f=1:length(Fields)
			fieldname = Fields{f};
			figure(meanfig.(fieldname));
		end
	end
    

