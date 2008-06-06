% A very simple code to illustrate the phase-shift in a plane wave
% Things become much more complex if the effects of diffraction are
% included.

plane_wave = 1;
spherical_wave = 2;

%wave_type = plain_wave;
wave_type = spherical_wave;

if wave_type == plane_wave

   % window size
   Lx=0.4;
   Lx=1;

   % blow up the image by this factor to display better
   factor = 0.1;

elseif wave_type == spherical_wave
      
      Lx = 0.5;
      Ly = Lx;
      factor = 1;
end;


Mx = Lx/2;
Wy = Ly/2;

M=400;
N = floor(M*Ly/Lx);

[X, Y]=meshgrid(linspace(-Lx/2, Lx/2, M), linspace(-Ly/2, Ly/2, N));


k = 100; % the wavenumber

T = 1;
nt = 10;
Time = linspace(0, T, nt);

% do several time periods
for q=1:10

   % go over one time period of the field
   for t=Time(1:(nt-1)) % nt will be same as 1 due to periodicity
      
      
% The Green's function in 2D for the Helmholtz equation
% is the bessel function of the first kind of index 0.

      if wave_type == plane_wave
         Z = real(exp(i*k*Y)*exp(-i*2*pi*t)); % plane wave
      elseif wave_type == spherical_wave 
         %Z = besselh(0, 1, k*sqrt(X.^2+Y.^2))*exp(-i*2*pi*t); % spherical wave
         Z = (exp(i*k*sqrt(X.^2+Y.^2))./sqrt(X.^2+Y.^2))*exp(-i*2*pi*t); % spherical wave
      end
      
% plot the real part of the field Z
      
      figure(1); clf; hold on; axis equal; axis off;
      image(factor*(real(Z+0.0))); % add something to Z (maybe) for graphing purposes
      colormap jet; shading interp;
      pause(0.25);
   end
end

%downshift = 1.5*Ly;
%%surf(X, Y+downshift, 1+real(W));
%
%%view(0, 90);
%shading flat;
%colormap copper;
%axis([0, Lx, 0, Ly+2*downshift]);
%
%view(90, 90);
%
%%saveas(gcf, 'Phase-shift_illustration.eps', 'psc2');
%print('-dpng', 'Phase-shift_illustration.png');
