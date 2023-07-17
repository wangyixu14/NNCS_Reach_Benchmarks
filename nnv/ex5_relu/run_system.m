% /* An example of verifying a continuous nonlinear NNCS */
% / FFNN controller

clc
clear

read_nn_file("nn_5_relu");

weights = load('net.mat', 'weights').weights;
bias = load('net.mat', 'bias').bias;
activations = load('net.mat', 'activations').activations;
n = length(weights);
Layers = [];
for i=1:n
    L = LayerS(weights{i}', bias{i}', activations(i));
    Layers = [Layers L];
end
controller = FFNNS(Layers); 
% /* car model
Tr = 0.005; % reachability time step for the plant
Tc = 0.2; % control period of the plant
% output matrix
C = [1 0 0; 0 1 0; 0 0 1]; % output matrix
num_states = 3;
num_inputs = 1;
system = NonLinearODE(num_states, num_inputs, @dynamics, Tr, Tc, C);

% /* system
ncs = NonlinearNNCS(controller, system); 

% /* ranges of initial set of states of the plant
lb = [0.38; 0.45; 0.25];
ub = [0.40; 0.47; 0.27];

% /* reachability parameters
reachPRM.init_set = Star(lb, ub);
reachPRM.ref_input = [];
reachPRM.numSteps = 1;
reachPRM.reachMethod = 'approx-star';
reachPRM.numCores = 1;

U = 0; % don't check safety for intermediate flowpipes

% /* verify the system
[safe, counterExamples, verifyTime] = ncs.verify(reachPRM, U);

%% compute reachability safety property at the end
map_mat = [1 0 0; 0 1 0];
map_vec = [];
all_flowpipes = ncs.getOutputReachSet(map_mat, map_vec);
last_flowpipe = Star.get_hypercube_hull(all_flowpipes{length(all_flowpipes)});
ncs.plotOutputReachSets('yellow', map_mat, map_vec);

x1_ub = 0.28;
x1_lb = -0.4;
x2_ub = 0.22;
x2_lb = 0.05;

if last_flowpipe.lb(1) >= x1_ub || last_flowpipe.lb(2) >= x2_ub || last_flowpipe.ub(1) <= x1_lb || last_flowpipe.ub(2) <= x2_lb
    safe = 'UNSAFE';
elseif last_flowpipe.ub(1) >= x1_ub || last_flowpipe.ub(2) >= x2_ub || last_flowpipe.lb(1) <= x1_lb || last_flowpipe.lb(2) <= x2_lb
    safe = 'UNKNOWN';
end

safe
verifyTime

%% save flowpipes
save('nnv_flowpipes_relu.mat', 'ncs');