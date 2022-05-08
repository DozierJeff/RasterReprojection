function B = interpolateGeolocatedRaster(X,Y,A,Xq,Yq,method)
%interpolate raster and keep NaNs from propagating
%Input
%   X,Y - coordinates of input values
%   A - input values
%   Xq,Yq - coordinates of interpolated values
%   method - interpolation method
%Output
%   B - interpolated raster

%memory check
RasterReprojectionMemoryCheck((numel(Xq)+numel(Yq))*8*size(A,3));

% coordinate check
CheckInputCoordinates(X,Y,Xq,Yq);

%should have enough memory, go ...
if ismatrix(A)
    noNaN = ~isnan(X) & ~isnan(Y) & ~isnan(A);
    if nnz(noNaN)
        F = scatteredInterpolant(X(noNaN),Y(noNaN),A(noNaN),method,'none');
    else
        F = scatteredInterpolant(X(:),Y(:),A(:),method,'none');
    end
    B = F(Xq,Yq);
elseif ndims(A)==3
    for k=1:size(A,3)
        V = A(:,:,k);
        % allocate on first pass
        if k==1
            noNaN = ~isnan(X) & ~isnan(Y) & ~isnan(V);
            if nnz(noNaN)
                F = scatteredInterpolant(X(noNaN),Y(noNaN),V(noNaN),method,'none');
            else
                F = scatteredInterpolant(X(:),Y(:),V(:),method,'none');
            end
            B1 = F(Xq,Yq);
            %memory check
            if ispc
                RasterReprojectionMemoryCheck(8*size(A,3)*(numel(B1)));
            end
            %allocate output space
            B = zeros(size(B1,1),size(B1,2),size(A,3));
        else
            if nnz(noNaN)
                F.Values = V(noNaN);
            else
                F.Values = V(:);
            end
            B1 = F(Xq,Yq);
        end
        B(:,:,k) = B1;
    end
else
    error('arrays of more than 3 dimensions not supported')
end
if all(isnan(B(:)))
    error('all interpolated values are NaN, check input and output coordinates')
end
end

function CheckInputCoordinates(X,Y,Xq,Yq)
inputX = [min(X(:)) max(X(:))];
inputY = [min(Y(:)) max(Y(:))];
% polygon
xv = [min(inputX) max(inputX) max(inputX) min(inputX) min(inputX)];
yv = [min(inputY) min(inputY) max(inputY) max(inputY) min(inputY)];
overlap = inpolygon(Xq,Yq,xv,yv);
if nnz(overlap)==0
    error('all the output coordinates are outside the quadrangle of the input coordinates')
end
end