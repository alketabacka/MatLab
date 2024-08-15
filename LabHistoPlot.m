function [ varargout ] = LabHistPolt( a,b )
%LabHistPlot a 2D histgram of the colour channels in a Lab image
%   [ h] = LabHistPolt( a,b ) a and b are the colour channel input arrays. It returns a
%   handle to the graphics

%new figure and return its handle
h=figure();
if nargout>0
    varargout{1}=h;
end

N=101; %number of bins;
bin_centers=linspace(-100,100,N);
subscripts = 1:N;
ai = interp1(bin_centers, subscripts, a, 'linear', 'extrap');
bi = interp1(bin_centers, subscripts, b, 'linear', 'extrap');
ai = round(ai);
bi = round(bi);

ai = max(min(ai, N), 1);
bi = max(min(bi, N), 1);
H = accumarray([bi(:), ai(:)], 1, [N N]);
xdata = [min(bin_centers), max(bin_centers)];
ydata = xdata;
[a,b]=meshgrid(linspace(xdata(1),xdata(2),N));
L=H/10;%/max(H(:))*100;
cf=makecform('lab2srgb');
cH=applycform(lab2uint8(cat(3,L,a,b)),cf);
imshow(cH, 'InitialMagnification', 300, 'XData', xdata, 'YData', ydata)
axis on
xlabel('a*')
ylabel('b*')
end
