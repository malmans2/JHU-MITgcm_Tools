function [TRANSPORT] = compute_Transport(Temprange,Srange,Sigma0range,InOutFlow,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat,plottransp)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Compute transport through a sections
%
% INPUT:
%       Temprange:   Cell array containing temperature limits
%		     e.g. Temprange = {[-2] [10]}
%		     Compute transport of water with -2<=Temp<=10
%       Srange:      Cell array containing salinity limits
%                    e.g. Srange = {[33] [35]}
%                    Compute transport of water with 33<=S<=35
%       Sigma0range: Cell array containing density limits
%                    e.g. Temprange = {[] [27.8]}
%                    Compute transport of water with Sigma0<=27.8
%       deltaT:      0 if Time defines every single time.
%                    Otherwise, set the timestep in days.
%                    e.g. deltaT = 0 or deltaT = 0.25 (6h)
%       Time:        if deltaT~=0, it defines the timerange.
%                    It must be a cell array (with 2 elements if deltaT~=0). 
%                    Format: 'dd-mmm-yyyy HH'
%                    e.g. Time = {'01-Sep-2007' ...}
%       Depthrange:  provide depth range in meters.
%                    It must be an array with 1 or 2 elements.
%                    e.g. Depthrange = [0 700]
%       Latrange:    provide transect's latitude range in degN.
%                    It must be an array with 1 or 2 elements.
%                    e.g. Latrange = [69 72]
%       Latrange:    provide transect's longitude range in degE.
%                    It must be an array with 1 or 2 elements.
%                    e.g. Lonrange = [-22 -13]
%       plotmap:     0: don't plot a map with the requested area
%                    1: plot a map with the requested area
%                    'filename': save map with the requested area to filename.eps
%       savemat:     Leave it empty if you don't want to save the output.
%                    If 'filename' is provided, filename.mat will be saved
%	plottransp:  0: don't plot the mean vertical sections
%		     1: plot the mean vertical sections
%		     'filename': save requested vertical sections to filename_Field.eps
% OUTPUT:
%       TRANSPORT: structure array containing transport.
%                 e.g. TRANSPORT.values
%			        .TIME
%                               .units

	% Set global variables 
        run set_globalvars

	% Check inputs
	if ~iscell(Temprange) | length(Temprange)~=2
		error('Error.\nTemprange must be a cell array with 2 elements',1)
	elseif ~iscell(Srange) | length(Srange)~=2
		error('Error.\nSrange must be a cell array with 2 elements',1)
	elseif ~iscell(Sigma0range) | length(Sigma0range)~=2
		error('Error.\nSigma0range must be a cell array with 2 elements',1)
        elseif ~iscell(Time) | isempty(Time)
                error('Error.\nTime must be a cell array with at least one element',1)
	elseif ~isempty(InOutFlow) 
		if all(InOutFlow~=[-1 1]) 
			error('Error.\nInOutFlow must be -1, 1 or empty',1)
		end
        elseif deltaT~=0 & length(Time)~=2
                error('Error.\nIf deltaT is not 0, Time defines the timerange and its size must be 2',1)
        elseif rem(deltaT,infonc.deltaT)~=0
                error('Error.\ndeltaT must be a multiple of [%1.2f]',infonc.deltaT)
	elseif length(Latrange) > 2 | isempty(Latrange)
                error('Error.\nLatrange must contain 1 or 2 elements',1)
        elseif length(Lonrange) > 2 | isempty(Lonrange)
                error('Error.\nLonrange must contain 1 or 2 elements',1)        
        elseif length(Depthrange) <2
                error('Error.\nDepthrange must contain 2 elements',1)
	elseif ~ischar(plotmap) & all(plotmap~=[0 1])
                error('Error.\nplotmap must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
        elseif ~isempty(savemat) & ~ischar(savemat)
                error('Error.\nLeave savemat empty if you do not want to save outputs. Otherwise, provide a string',1)
	elseif isempty(plottransp) | (~ischar(plottransp) & all(plottransp~=[0 1]))
                error('Error.\nplottransp must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
	end

	% Compute OrtVel
	FieldsVS    = {'OrtVel'};
	savematVS   = [];
	plotmeanVS  = [0];
	savemovieVS = [];
	[VSVEL] = compute_VSVelocities(FieldsVS,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savematVS,plotmeanVS,savemovieVS);
	TRANSPORT = [];
	
	% Read dimensions and create interpolated dimensions
	dist      = VSVEL.('OrtVel').('DIST') * 1.e3; % m
	depth     = VSVEL.('OrtVel').('DEPTH');
	time      = VSVEL.('OrtVel').('TIME');
	idist     = (dist(1:end-1) + dist(2:end)) /2;
	idepth    = (depth(1:end-1) + depth(2:end)) /2;
	if length(depth)<2
		error('Error.\nDepth range is too small',1)
	end

	% Compute area
	diffdist  = diff(dist);
        diffdepth = diff(depth);
	[dDIST,dDEPTH,~] = ndgrid(diffdist,diffdepth,time);
	AREA = dDIST.*dDEPTH; % m^2

	% Interpolate OrtVel
	fprintf(logID,'\n Interpolating velocities:');
	tic
	if length(time)>1
		[DIST,DEPTH,TIME]    = ndgrid(dist,depth,time);
		[iDIST,iDEPTH,iTIME] = ndgrid(idist,idepth,time);
		OrtVel               = interpn(DIST,DEPTH,TIME,VSVEL.('OrtVel').('values'),iDIST,iDEPTH,iTIME);
	else
		[DIST,DEPTH]    = ndgrid(dist,depth);
                [iDIST,iDEPTH]  = ndgrid(idist,idepth);
                OrtVel          = interpn(DIST,DEPTH,VSVEL.('OrtVel').('values'),iDIST,iDEPTH);
	end
	fprintf(logID,' done in %f seconds\n',toc);
	
	% Read limit fields
	limFields = {};
	if ~isempty(Temprange{1}) | ~isempty(Temprange{2})
		limFields(length(limFields)+1) = {'Temp'};
		lims.('Temp') = Temprange;
	end
	if ~isempty(Srange{1}) | ~isempty(Srange{2})
		limFields(length(limFields)+1) = {'S'};
		lims.('S') = Srange;
        end
	if ~isempty(Sigma0range{1}) | ~isempty(Sigma0range{2})
		limFields(length(limFields)+1) = {'Sigma0'};
		lims.('Sigma0') = Sigma0range;
        end
	
	if length(limFields)>=1
		plotmapVS  = [0]; 
		[VERTSECS] = create_VerticalSection(limFields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmapVS,savematVS,plotmeanVS,savemovieVS);
	end

	MASK = ones(size(OrtVel));
	for f = 1:length(limFields)
		fieldname = limFields{f};
		fprintf(logID,'\n Interpolating [%s]:',fieldname);
		tic
		if length(time)>1
                	msk.(fieldname) = interpn(DIST,DEPTH,TIME,VERTSECS.(fieldname).('values'),iDIST,iDEPTH,iTIME);
       		else
                	msk.(fieldname) = interpn(DIST,DEPTH,VERTSECS.(fieldname).('values'),iDIST,iDEPTH);
        	end
		fprintf(logID,' done in %f seconds\n',toc);
		if ~isempty(lims.(fieldname){1})
			MASK(msk.(fieldname)<lims.(fieldname){1}) = 0;
		end
		if ~isempty(lims.(fieldname){2})
			MASK(msk.(fieldname)>lims.(fieldname){2}) = 0;
		end
	end
	
	if InOutFlow == 1
		MASK(OrtVel<0) = 0;
	elseif InOutFlow == -1
		MASK(OrtVel>0) = 0;
	end
	Transport = OrtVel .* AREA .* MASK .*1.e-6; %SV
	Transport = squeeze(Transport);
	for t = 1:length(time)
		thistran                  = Transport(:,:,t);
		TRANSPORT.('values')(t,:) = nansum(thistran(:));
	end
	TRANSPORT.('TIME')  = time;
	TRANSPORT.('units') = 'Sv';


	% Save fields
        tic
        if ~isempty(savemat)
                sz = whos('TRANSPORT');
                sz = sz.bytes * 1.e-9; % GB
                fprintf(logID,'\n Saving transport to mat-file [%s.mat]',savemat);
                if round(sz)>=2
                        fprintf(logID,' using compression (v7.3)');
                        save(savemat,'TRANSPORT','-v7.3')
                else
                        save(savemat,'TRANSPORT')
                end
                % Timing
                fprintf(logID,': done in %f seconds\n',toc);
        end

	% Plot
	if plottransp~=0 & length(time)>1
		transport = TRANSPORT.('values');
		
		% Figure
		fig = figure('PaperPosition',[.25 .25 8 6]);
                hold on
		ylim([nanmin(transport) nanmax(transport)]);
		title('Transport')

		% Plot
		lWidth = 2;
                mSize  = 3;
		h1 = plot(time(~isnan(transport)),transport(~isnan(transport)),'b-o','LineWidth',lWidth,'MarkerSize',mSize);
		h2 = plot(time,repmat(nanmean(transport),size(time)),'r--','LineWidth',lWidth,'MarkerSize',mSize);
		datetick('x','dd/mm/yy')
		xlim([nanmin(time(:)) nanmax(time(:))])
              	legend([h1,h2],'timeseries','mean','Location','best')
		
		if ischar(plottransp)
               		% Save figure
                       	filename = [plottransp];
                     	fprintf(logID,'\n Saving transport timeseries to [%s.eps]:',filename);
                      	tic
                        print(filename,'-depsc2','-r300');
                        fprintf(logID,' done in %f seconds\n',toc);
             	end
	elseif length(time)<=1
		fprintf(logID,'\n NO plot because only 1 timestep has been selected \n');
	end


