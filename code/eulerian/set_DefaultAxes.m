%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Set default axes properties and remove anoying warnings

% Set default axes properties
set(0,'DefaultAxesFontSize',15)
set(0,'DefaultAxesFontWeight','bold')

% Remove warnings
warning('off','MATLAB:hg:AutoSoftwareOpenGL')
warning('off','MATLAB:handle_graphics:Patch:NumColorsNotEqualNumVertsOrNumFacesException')
