% Illustration of a wave packet

L = 1.7; % 2*L=length of domain
A = 1.2; % max amplitude

K = 1.3; % gaussian param
fast_wl = 52;
slow_wl = 4;

N = 500; % num of data points
lw = 40; % linewidth of curves

X = linspace(-L, L, N);
%Y = cos(X*slow_wl)./(1 + (X/K).^2);
q=1.5;
Y = A*cos(abs(X).^q*slow_wl).*exp(-K*X.^2);

num_P=1; % how many periods to keep
Y( find (abs(X) > ((2*num_P+0.5)*pi/slow_wl)^(1/q)) )=0;
Z = Y.*cos(fast_wl*X);

% KSmrq's colors
red    = [0.867 0.06 0.14];
blue   = [0, 129, 205]/256;
green  = [0, 200,  70]/256;
yellow = [254, 194,   0]/256;
white = 0.99*[1, 1, 1];
black = [0, 0, 0];

figure(1); clf; hold on; axis equal; axis off;
lw2=0.7*lw;
plot(X, Y, 'color', red, 'linewidth', lw2, 'linestyle', '--')
plot(X, -Y, 'color', red, 'linewidth', lw2, 'linestyle', '--')
plot(X, Z,  'color', blue, 'linewidth', lw)

saveas(gcf, 'Wave_packet.eps', 'psc2')
plot2svg('/u/cedar/h1/afa/aoleg/public_html/Wave_packet.svg')

