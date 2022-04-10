function [ RR, varargout ] = rasterrefMODtile( tile )
% [ RR ] = rasterrefMODtile( tile )
% [ RR,GeoKeyDirectoryTag ] = rasterrefMODtile( tile )
% [ RR,GeoKeyDirectoryTag,latlonCorners ] = rasterrefMODtile( tile )
% (next option only for MATLAB versions before 2020b)
% [ RR,GeoKeyDirectoryTag,latlonCorners,pstruct ] = rasterrefMODtile( tile )
%
%Coordinate and projection information for any single MODIS tile
%
% Input
%   tile - 6-character MODIS tile designation in form 'hNNvNN'
%
% Output
%   RR - structure containing the mapRasterReference objects for each of
%       the MODIS resolutions: 250 m, 500 m, 1 km
% Optional output, if specified in output arguments as above
%   GeoKeyDirectoryTag - structure containing the various GeoKeys for input
%       to a GeoTIFF file
%   latlonCorners - latitudes and longitudes for each corner, counter-
%       clockwise from upper left, 4x2 matrix with latitudes in column 1,
%       longitudes in column 2
%   pstruct - projection structure, use only if MATLAB versions before
%       R2020b with Mapping Toolbox 5.0
%
% The function assumes that the grid origin is in the upper left

% tile sizes for 1km, 500m, 250m - hardwired
tilesize = [1200 1200; 2400 2400; 4800 4800];

% referencing matrix
% x- and y-coordinates of this tile's upper left corner
[ULx,ULy,tileHeight,tileWidth] = MODtile2xy(tile);
pixelHeight = tileHeight./tilesize(:,1);
pixelWidth = tileWidth./tilesize(:,2);

% coordinates of center (not the corner) of upper left pixel
% (these are vectors because pixelWidth and pixelHeight are vectors)
x11 = ULx+pixelWidth/2;
y11 = ULy-pixelHeight/2; % negative because y(n)>y(n+1)

% Referencing matrices, note that makerefmat will be deprecated someday so
% disable warning
warnID = 'map:removing:makerefmat';
warnStruct = warning('off',warnID);
refmat = {'RefMatrix_1km','RefMatrix_500m','RefMatrix_250m'};
assert(length(refmat)==length(pixelWidth),...
    'number of referencing matrices (%d) does not equal number of tile sizes (%d)',...
    length(refmat),length(pixelWidth))
for gn=1:length(refmat)
    RefMatrix.(refmat{gn}) = makerefmat(x11(gn),y11(gn),...
        pixelWidth(gn),-pixelHeight(gn)); %#ok<MKRMT>
end
warning(warnStruct); % re-enable warning

% loop through the possible arguments
if nargout>1
    varargout = cell(nargout-1,1);
end
if iscell(tile)
    tile = char(tile);
end
for k=1:nargout
    switch k
        case 1 % map raster references, required
            rasterref = {'RasterReference_1km','RasterReference_500m','RasterReference_250m'};
            assert(length(rasterref)==length(refmat),...
                'bug in code, length(rasterref)=%d, length(refmat)=%d',...
                length(rasterref),length(refmat))
            for gn=1:length(refmat)
                RasterReference.(rasterref{gn}) =...
                    refmatToMapRasterReference(RefMatrix.(refmat{gn}),...
                    tilesize(gn,:));
                % good for versions R2020b and later
                if ~verLessThan('map','5.0'),...
                        RasterReference.(rasterref{gn}).ProjectedCRS = MODISsinusoidal;
                end
            end
            RR = RasterReference;
        case 2 % GeoKeyDirectoryTag
            CT_Sinusoidal = 24;
            ModelTypeProjected = 1;
            RasterPixelIsArea = 1;
            LinearMeter = 9001;
            AngularDegree = 9102;
            key.GTModelTypeGeoKey = ModelTypeProjected;
            key.GTRasterTypeGeoKey = RasterPixelIsArea;
            key.GeogLinearUnitsGeoKey = LinearMeter;
            key.GeogAngularUnitsGeoKey = AngularDegree;
            key.ProjectedCSTypeGeoKey = CT_Sinusoidal;
            varargout{k-1} = key;
        case 3 % lat-lon of corners
            [clat,clon] = MODtile2latlon(tile);
            varargout{k-1} = [clat clon];
        case 4
            % only for versions before R2020b
            if verLessThan('map','5.0'),...
                    varargout{k-1} = MODISsinusoidal;
            else
                warning('for MATLAB versions R2020b (Mapping Toolbox 5.0) and later, projection information is returned in the raster reference so the 4th output is ignored')
                varargout{k-1} = struct([]);
            end
        otherwise
            error('too many output arguments')
    end
end
end