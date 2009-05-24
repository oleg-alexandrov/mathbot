% Illustration of Laplace's method

N   = 500;
L   = 15;
fs  = 12;
lw  = 2;
lw2 = 1;

X = linspace(-L, L, N)+eps;
f = sin(X)./X;
g = (1-X.^2/6);


figure(1); clf; hold on;
q = 1.01;

subplot(2, 3, 1);
set(gca, 'fontsize', fs);
set(gca, 'LineWidth', lw2);
hold on;
M = 0.5;
Y = exp(M*f);
Z = exp(M*g);
plot(X, Z, 'r', 'linewidth', lw);
plot(X, Y, 'b', 'linewidth', lw);
R = max(Z);
axis([-L, L, 0, q*R]);

subplot(2, 3, 4);
set(gca, 'fontsize', fs);
set(gca, 'LineWidth', lw2);
hold on;
M = 3;
Y = exp(M*f);
Z = exp(M*g);
plot(X, Z, 'r', 'linewidth', lw);
plot(X, Y, 'b', 'linewidth', lw);
R = max(Z);
axis([-L, L, 0, q*R]);

saveas(gcf, 'Laplaces_method.eps', 'psc2');

% Converted from eps to png with the formula
% convert -antialias -density 200 Laplaces_method.eps Laplaces_method.png