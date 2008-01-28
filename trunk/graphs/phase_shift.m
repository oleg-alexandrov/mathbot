% A very simple code to illustrate the phase-shift in a plane wave
% Things become much more complex if the effects of diffraction are
% included.

Lx=1;
Ly=0.4;

Mx = Lx/2;
Wy = Ly/2;

M=400;
N = floor(M*Ly/Lx);

[X, Y]=meshgrid(linspace(0, Lx, M), linspace(0, Ly, N));


k = 100; % the wavenumber
Z = real(exp(i*k*X));

% The field Z with a phase-shifted part
S = find ( X > Mx & Y < Ly/2 + Wy/2 & Y > Ly/2 - Wy/2);
W = Z;
W(S) = W(S)*exp(i*pi);


figure(1); clf; hold on; axis equal; axis off;
surf(X, Y, real(Z));

downshift = 1.5*Ly;
surf(X, Y+downshift, real(W));

view(0, 90);
shading flat;
colormap copper;
axis([0, Lx, 0, Ly+2*downshift]);

view(90, 90);

%print(gcf, '-dpng', 'Phase-shift_illustration.png');
saveas(gcf, 'Phase-shift_illustration.eps', 'psc2');
