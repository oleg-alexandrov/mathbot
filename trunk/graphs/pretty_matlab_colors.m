% colors

red=[0.867 0.06 0.14];
blue = [0, 129, 205]/256;
green = [0, 200,  70]/256;

thickness = 3;

a= -pi; b = pi; N = 100;
X=linspace(a, b, N);


Y = sin(X);
Z = cos(X);
W = cos(2*X);

figure(1); clf; hold on;
plot(X, Y, 'linewidth', thickness, 'color', red);
plot(X, Z, 'linewidth', thickness, 'color', blue);
plot(X, W, 'linewidth', thickness, 'color', green);