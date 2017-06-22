function [HORSECS] = create_HorizontalSection(Fields,Time,deltaT,Depth,Latrange,Lonrange,plotmap,savemat,plotmean,savemovie)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Read MITgcm outputs and create a horizontal section.
% Global variables are called by run set_globalvars
%
% INPUT:
%       Fields:     cell array containing fields' names
%                   e.g. Fields = {'Temp' 'S' 'U' ...}
%       deltaT:     0 if Time defines every single time.
%                   Otherwise, set the timestep in days.
%                   e.g. deltaT = 0 or deltaT = 0.25 (6h)
%       Time:       if deltaT~=0, it defines the timerange.
%                   It must be a cell array (with 2 elements if deltaT~=0). 
%                   Format: 'dd-mmm-yyyy HH'
%                   e.g. Time = {'01-Sep-2007' ...}
%       Depthrange: provide depth range in meters.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Depthrange = [0 700]
%       Latrange:   provide transect's latitude range in degN.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Latrange = [69 72]
%       Latrange:   provide transect's longitude range in degE.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Lonrange = [-22 -13]
%       plotmap:    0: don't plot a map with the requested area
%                   1: plot a map with the requested area
%                   'filename': save map with the requested area to filename.eps
%       savemat:    Leave it empty if you don't want to save the output.
%                   If 'filename' is provided, filename.mat will be saved
%	plotmean:   0: don't plot the mean vertica sections
%		    1: plot the mean vertical sections
%		    'filename': save requested vertical sections to filename_Field.eps
%       savemovie:  Leave it empty if you don't want to save movies (loop over time). 
%                   If 'filename' is provided, filename_Field.mat will be saved
%
% OUTPUT:
%       VERTSECS: structure array containing vertical sections.
%                 e.g. VERTSECS.Temp.values
%			    	     bathy
%                                    dimensions
%                                    LON
%                                    LAT
%                                    DIST
%                                    TIME
%				     DEPTH
%                                    units
%                                    long_name
%

	% Set global variables 
        run set_globalvars

	% Check inputs
        checkFields        = infonc.vars.NAME;
        checkFields{end+1} = 'Sigma0';
        if ~iscell(Fields) | isempty(Fields)
                error('Error.\nFields must be a cell array with at least one element',1)
        elseif ~all(ismember(Fields,checkFields))
                error('Error.\nField [%s] not available',Fields{min(find(~ismember(Fields,checkFields)==1))})
        elseif ~iscell(Time) | isempty(Time)
                error('Error.\nTime must be a cell array with at least one element',1)
        elseif deltaT~=0 & length(Time)~=2
                error('Error.\nIf deltaT is not 0, Time defines the timerange and its size must be 2',1)
        elseif rem(deltaT,infonc.deltaT)~=0
                error('Error.\ndeltaT must be a multiple of [%1.2f]',infonc.deltaT)
	elseif length(Latrange) > 2 | isempty(Latrange)
                error('Error.\nLatrange must contain 1 or 2 elements',1)
        elseif length(Lonrange) > 2 | isempty(Lonrange)
                error('Error.\nLonrange must contain 1 or 2 elements',1)        
        elseif length(Depth) ~=1 
                error('Error.\nDepth must contain 1 element',1)
	elseif ~ischar(plotmap) & all(plotmap~=[0 1])
                error('Error.\nplotmap must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
        elseif ~isempty(savemat) & ~ischar(savemat)
                error('Error.\nLeave savemat empty if you do not want to save outputs. Otherwise, provide a string',1)
	elseif isempty(plotmean) | (~ischar(plotmean) & all(plotmean~=[0 1]))
                error('Error.\nplotmean must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
        elseif ~isempty(savemovie) & ~ischar(savemovie)
                error('Error.\nLeave savemovie empty if you do not want to save the movie. Otherwise, provide a string',1)
        end

	% Read fields
        savefields   = [];
	interpC      = 1;
        [HORSECS]    = read_Fields(Fields,Time,deltaT,Depth,Latrange,Lonrange,plotmap,savefields,interpC);

	% Save horizontal sections
        tic
        if ~isempty(savemat)
                sz = whos('HORSECS');
                sz = sz.bytes * 1.e-9; % GB
                fprintf(logID,'\n Saving horizontal sections to mat-file [%s.mat]',savemat);
                if round(sz)>=2
                        fprintf(logID,' using compression (v7.3)');
                        save(savemat,'HORSECS','-v7.3')
                else
                        save(savemat,'HORSECS')
                end
                % Timing
                fprintf(logID,': done in %f seconds\n',toc);
        end

	
	% Plot Horizontal Section
	LAT = HORSECS.(Fields{1}).('LAT');
        LON = HORSECS.(Fields{1}).('LON');
	if length(LAT)>=2 & length(LON)>=2
		for f=1:length(Fields)
			fieldname = Fields{f};
        		LAT       = HORSECS.(fieldname).('LAT');
        		LON       = HORSECS.(fieldname).('LON');
			DEPTH     = HORSECS.(fieldname).('DEPTH');
			TIME      = HORSECS.(fieldname).('TIME');
			units     = HORSECS.(fieldname).('units');
			long_name = HORSECS.(fieldname).('long_name');
			field     = HORSECS.(fieldname).('values');
			if plotmean~=0
				% Create mean field
                        	meanfld = squeeze(nanmean(field,4));
			
				% Figure
                        	meanfig.(fieldname) = figure('visible','off','PaperPosition',[.25 .25 8 6]);
        			hold on
        			axis off
        			axesm(  'MapProjection','mercator',...
                			'MapLatLimit',[min(LAT) max(LAT)],...
                			'MapLonLimit',[min(LON) max(LON)],...
                			'Frame','on',...
                			'FFill',0,...
                			'FEdgeColor',[0 0 0],...
                			'FFaceColor',[0.4 0.4 0.4],...
                			'Grid','on',...
					'MLineLocation',linspace(min(LON),max(LON),5),...
                			'PLineLocation',linspace(min(LAT),max(LAT),5),...
                			'GColor',[0 0 0],...
                			'GLineStyle',':',...
                			'GLineWidth',0.5,...
                			'FontSize',15,...
                			'FontWeight','bold',...
                			'LabelFormat','signed',...
                			'MeridianLabel','on',...
					'MLabelLocation',linspace(min(LON),max(LON),5),...
                			'ParallelLabel','on',...
					'PLabelLocation',linspace(min(LAT),max(LAT),5),...
					'MLabelParallel','south');
				cbar = colorbar();
				cbar.Label.String = units;
				caxis([nanmin(meanfld(:)) nanmax(meanfld(:))])
				if ~isempty(DEPTH)
					title({long_name ['Depth=' num2str(DEPTH) 'm']},'Interpreter','none')
				else
					title(long_name,'Interpreter','none')
				end
				% Plot field
				h1 = pcolorm(LAT,LON,meanfld');

				if ischar(plotmean)
                                        % Save figure
                                        filename = [plotmean '_' fieldname];
                                        fprintf(logID,'\n Saving mean [%s] horizontal section to [%s.eps]:',fieldname,filename);
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
                                % hold on                                                                                                     
                               	
				% Create movie
				for t=1:length(TIME)
					axis off                                                                                                    
                          		axesm(  'MapProjection','mercator',... 
						'MapLatLimit',[min(LAT) max(LAT)],...                                                  
						'MapLonLimit',[min(LON) max(LON)],...                              
						'Frame','on',...              
						'FFill',0,...          
						'FEdgeColor',[0 0 0],...                                           
						'FFaceColor',[0.4 0.4 0.4],...                                 
						'Grid','on',...                       
						'MLineLocation',linspace(min(LON),max(LON),5),...              
						'PLineLocation',linspace(min(LAT),max(LAT),5),...       
						'GColor',[0 0 0],...                                             
						'GLineStyle',':',...                                              
						'GLineWidth',0.5,...                                                
						'FontSize',15,...                                 
						'FontWeight','bold',...                                                
						'LabelFormat','signed',...                                     
						'MeridianLabel','on',...       
						'MLabelLocation',linspace(min(LON),max(LON),5),...             
						'ParallelLabel','on',...                                   
						'PLabelLocation',linspace(min(LAT),max(LAT),5),...           
						'MLabelParallel','south');                                       
					cbar = colorbar();                                                                    
					cbar.Label.String = units;                                                 
					caxis([nanmin(field(:)) nanmax(field(:))]) 		
			
					fld = squeeze(field(:,:,:,t));
					% Title
					if ~isempty(DEPTH)
                                        	title({long_name ['Depth=' num2str(DEPTH) 'm']  datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
                                	else
                                        	title({long_name datestr(TIME(t),'dd-mmm-yyyy HH')},'Interpreter','none')
                                	end
					% Plot field
                                	h1 = pcolorm(LAT,LON,fld');
					% Create movie
                                        frame = getframe(moviefig);
					% Clear plot
                                        cla
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
        	
			if plotmean~=0
                		for f=1:length(Fields)
                        		fieldname = Fields{f};
                               		figure(meanfig.(fieldname));
                     		end
           		end
		end
	elseif length(LAT)<2 & length(LON)<2
		VERTSECS = HORSECS;
		for f=1:length(Fields)
                       	fieldname = Fields{f};
                       	LAT       = VERTSECS.(fieldname).('LAT');
                       	LON       = VERTSECS.(fieldname).('LON');
                       	DEPTH     = VERTSECS.(fieldname).('DEPTH');
                       	TIME      = VERTSECS.(fieldname).('TIME');
			field     = VERTSECS.(fieldname).('values');
			DIST      = deg2km(distance(LAT(1),LON(1),LAT,LON));
				
			VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
			VERTSECS.(fieldname).('DIST')       = DIST;
			VERTSECS.(fieldname).('values')     = reshape(field,length(DIST),length(DEPTH),length(TIME));
		end
		% Plot using VERTSECS
		plot_VerticalSection(Fields,VERTSECS,plotmean,savemovie)
	elseif length(LAT)<2
		VERTSECS = HORSECS;
                for f=1:length(Fields)
                	fieldname = Fields{f};
                     	LAT       = VERTSECS.(fieldname).('LAT');
                      	LON       = VERTSECS.(fieldname).('LON');
			LAT       = repmat(LAT,size(LON));
                      	DEPTH     = VERTSECS.(fieldname).('DEPTH');
                      	TIME      = VERTSECS.(fieldname).('TIME');
                      	field     = VERTSECS.(fieldname).('values');
                     	DIST      = deg2km(distance(LAT(1),LON(1),LAT,LON));

                     	VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
			VERTSECS.(fieldname).('LAT')        = LAT;				
                       	VERTSECS.(fieldname).('DIST')       = DIST;
                     	VERTSECS.(fieldname).('values')     = reshape(field,length(DIST),length(DEPTH),length(TIME));
            	end
              	% Plot using VERTSECS
               	plot_VerticalSection(Fields,VERTSECS,plotmean,savemovie)

	elseif length(LON)<2
		VERTSECS = HORSECS;
               	for f=1:length(Fields)
                	fieldname = Fields{f};
                      	LAT       = VERTSECS.(fieldname).('LAT');
                      	LON       = VERTSECS.(fieldname).('LON');
                      	LON       = repmat(LON,size(LAT));
                      	DEPTH     = VERTSECS.(fieldname).('DEPTH');
                      	TIME      = VERTSECS.(fieldname).('TIME');
                       	field     = VERTSECS.(fieldname).('values');
                     	DIST      = deg2km(distance(LAT(1),LON(1),LAT,LON));

                     	VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
                     	VERTSECS.(fieldname).('LON')        = LON;
                     	VERTSECS.(fieldname).('DIST')       = DIST;
                      	VERTSECS.(fieldname).('values')     = reshape(field,length(DIST),length(DEPTH),length(TIME));
           	end
               	% Plot using VERTSECS
                plot_VerticalSection(Fields,VERTSECS,plotmean,savemovie)
	end

%}
