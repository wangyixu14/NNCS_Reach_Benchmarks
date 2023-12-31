function completed = example_neuralNet_reach_02_ACC
% example_neuralNet_reach_02_ACC - example of reachability analysis for a
%                                  neural network adaptive cruise control
%
%
% Syntax:
%    completed = example_neuralNet_reach_02_unicycle()
%
% Inputs:
%    no
%
% Outputs:
%    completed - boolean
%
% Reference:
%   [1] Johnson, Taylor T., et al. "ARCH-COMP21 Category Report:
%       Artificial Intelligence and Neural Network Control Systems (AINNCS)
%       for Continuous and Hybrid Systems Plants."
%       EPiC Series in Computing 80 (2021): 90-119.
%   [2] Model Predictive Control Toolbox.
%       The MathWorks Inc., Natick, Massachusetts (2019).
%       https://www.mathworks.com/help/mpc/ug/adaptive-cruisecontrol-using-model-predictive-controller.html
%
% Author:       Niklas Kochdumper, Tobias Ladner
% Written:      08-November-2021
% Last update:  20-May-2022 (TL: ARCH'22 Revisions)
% Last revision:---

%------------- BEGIN CODE --------------

disp("BENCHMARK: Adaptive Cruise Controller (ACC)")
disp("Here")


% Parameter ---------------------------------------------------------------

%R0 = interval([90; 32; 0; 10; 30; 0], [91; 32.05; 0; 11; 30.05; 0]);
R0 = interval([30; 1.4; 90; 10; 32; 30; 0; 0], [30; 1.4; 91; 11; 32.05; 30.05; 0; 0]);
params.tFinal = 5.;
params.R0 = polyZonotope(R0);

% Reachability Settings ---------------------------------------------------

options.timeStep = 0.02;
options.taylorTerms = 6;
options.zonotopeOrder = 200;
options.alg = 'lin';
options.tensorOrder = 2;

% Parameters for NN evaluation --------------------------------------------
evParams = struct();
evParams.bound_approx = true;
evParams.polynomial_approx = "lin";
evParams.add_approx_error_to_Grest = true;
evParams.remove_Grest = false;

% System Dynamics ---------------------------------------------------------

% parameter
u_f = 0.0001;
a_lead = -2;
v_set = 30;
T_gap = 1.4;
D_default = 10;

% open-loop system
f = @(x, u) [0; 0; x(5); x(6); x(7); x(8);
    -4 - 2*x(7) - 0.0001*x(5)^2;
    2*u(1) - 2*x(8) - 0.0001*x(6)^2];
sys = nonlinearSys(f);

% % affine map x_ = C*x + k mapping state x to input of neural network x_
% C = [0, 0, 0, 0, 0, 0; 0, 0, 0, 0, 0, 0; 0, 0, 0, 0, 1, 0; 1, 0, 0, -1, 0, 0; 0, 1, 0, 0, -1, 0];
% k = [v_set; T_gap; 0; 0; 0];

% load neural network controller
% [5, 20, 20, 20, 20, 20, 1]

% load neural network controller
nn = NeuralNetwork.readONNXNetwork('acc_tanh20x20x20_.onnx');
% load('controllerACC.mat');
%  
%  actFun = [{'identity'}, repmat({'ReLU'}, [1, length(W)])];
%  W = [{C}, W];
%  b = [{k}, b];
%  
%  nn = neuralNetwork(W, b, actFun);

% construct neural network controlled system
sys = neurNetContrSys(sys, nn, 0.1);

tic
R = reach(sys, params, options, evParams);
tComp = toc;
disp(['Time to compute Reachable Set: ', num2str(tComp)]);

% Visualization -----------------------------------------------------------
disp("Plotting..")

figure;
hold on;
box on;

rs = plot(R, [5, 6], 'FaceColor', [.7, .7, .7]);
is = plot(R0, [5, 6], 'FaceColor', 'w', 'EdgeColor', 'k');
rectangle('Position', [22.81 29.88 0.06 0.14]);
%ss = plot(simRes, [4, 5], 'Color', 'k');

% % Simulation --------------------------------------------------------------
% 
tic;
simRes = simulateRandom(sys, params);
tSim = toc;
disp(['Time to compute random Simulations: ', num2str(tSim)]);
% 
% % Check Violation --------------------------------------------------------
% 
% goalSet = interval(-[0.6; 0.2; 0.06; 0.3], [0.6; 0.2; 0.06; 0.3]);
% tic
% isVio = false;
% for i = 1:length(simRes.x)
%     % relative distance D_rel
%     distance = [1, 0, 0, -1, 0, 0]*simRes.x{i}';
%     safe_distance = D_default + [0, 0, 0, 0, T_gap, 0]*simRes.x{i}';
%     % safe distance D_safe
%     isVio = isVio || ~all(distance >= safe_distance);
% end
% tVio = toc;
% disp(['Time to check Violation in Simulations: ', num2str(tVio)]);
% 
% if isVio
%     disp("Result: VIOLATED")
%     R = params.R0;
%     tComp = 0;
%     tVeri = 0;
% else
%     % Reachability Analysis -----------------------------------------------
% 
%     tic
%     R = reach(sys, params, options, evParams);
%     tComp = toc;
%     disp(['Time to compute Reachable Set: ', num2str(tComp)]);
% 
%     % Verification --------------------------------------------------------
% 
%     tic
%     isVeri = true;
%     for i = 1:length(R)
%         for j = 1:length(R(i).timeInterval.set)
%             % relative distance D_rel
%             distance = interval([1, 0, 0, -1, 0, 0]*R(i).timeInterval.set{j});
%             safe_distance = D_default + interval([0, 0, 0, 0, T_gap, 0]*R(i).timeInterval.set{j});
%             % safe distance D_safe
%             isVeri = isVeri && (infimum(distance) > supremum(safe_distance));
%         end
%     end
%     tVeri = toc;
%     disp(['Time to check Verification: ', num2str(tVeri)]);
% 
%     if isVeri
%         disp('Result: VERIFIED');
%     else
%         disp('Result: UNKOWN')
%     end
% end
% 
% disp(['Total Time: ', num2str(tSim+tVio+tComp+tVeri)]);
% 
% % Visualization -----------------------------------------------------------
% disp("Plotting..")
% 
% figure;
% hold on;
% box on;
% 
% rs = plot(R, [4, 5], 'FaceColor', [.7, .7, .7]);
% is = plot(R0, [4, 5], 'FaceColor', 'w', 'EdgeColor', 'k');
% ss = plot(simRes, [5, 6], 'Color', 'k');
% plot reachable sets
% for i = 1:length(R)
%     for j = 1:length(R(i).timeInterval.set)
% 
%         time = R(i).timeInterval.time{j};
% 
%         % relative distance D_rel
%         temp = interval([1, 0, 0, -1, 0, 0]*R(i).timeInterval.set{j});
%         h1 = plot(cartProd(time, temp), [1, 2], 'FaceColor', [0, .8, 0]);
% 
%         % safe distance D_safe
%         temp = D_default + interval([0, 0, 0, 0, T_gap, 0]*R(i).timeInterval.set{j});
%         h2 = plot(cartProd(time, temp), [1, 2], 'FaceColor', [0.8, 0, 0]); 
%     end
% end
% 
% % plot simulation
% for i = 1:length(simRes.x)
%     % relative distance D_rel
%     distance = [1, 0, 0, -1, 0, 0]*simRes.x{i}';
%     safe_distance = D_default + [0, 0, 0, 0, T_gap, 0]*simRes.x{i}';
%     % safe distance D_safe
%     ss = plot(simRes.t{i}, distance,'Color', 'k');
% %     plot(simRes.t{i}, safe_distance, 'Color', [0.7, 0, 0])
% end

% xlabel('time');
% ylabel('distance');
%legend([rs, is], 'reachable set', 'initial set');

% example completed
completed = 1;

%------------- END OF CODE --------------
