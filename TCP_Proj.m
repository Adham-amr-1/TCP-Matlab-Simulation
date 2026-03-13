%% ============================================================
%                   TCP SIMULATION PROJECT
% ============================================================
%  1) Network Topology Definition
%  2) Three-Way Handshake
%  3) Flow Control  (Sliding Window)
%  4) Congestion Control (Slow Start + Congestion Avoidance)
%  5) Data Transmission Simulation
%  6) Performance Evaluation (Throughput)
%  7) Visualization
% ============================================================

%% ============================================================
%  Section 1 : Network Topology
% ============================================================
%   Sender ----> Router1 ----> Router2 ----> Receiver
%     1  -------->  2  -------->  3  -------->   4
%  BW :    10Mbps       10Mbps        10Mbps
%  Delay :   5ms          10ms           5ms
% ============================================================
clc; clear; close all;

numNodes       = 4;
nodePositions  = rand(numNodes, 2);
links          = [1 2; 2 3; 3 4];
linkBandwidths = [10, 10, 10];   % Mbps
linkDelays     = [5,  10,  5];   % ms

disp('====== Network Topology ======');
disp(['Nodes      : ' num2str(numNodes)]);
disp( 'Links      : Sender -> Router1 -> Router2 -> Receiver');
disp(['Bandwidths : ' num2str(linkBandwidths) ' Mbps']);
disp(['Delays     : ' num2str(linkDelays)     ' ms']);
disp('------------------------------');

%% ============================================================
%  Section 2 : TCP Three-Way Handshake
% ============================================================
disp('====== TCP Three-Way Handshake ======');
status = tcpHandshake(1, 4);
disp(status);
disp('-------------------------------------');
disp(' ');

%% ============================================================
%  Section 3 : Simulation Parameters
% ============================================================
totalPackets    = 100;       % Total packets to send
packetSize      = 1500 * 8;  % Packet size in bits (1500 Bytes = 12000 bits)
windowSize      = 10;        % Receiver advertised window size (packets)
cwnd            = 1;         % Initial congestion window (packets)
ssthresh        = 16;        % Initial slow-start threshold
lossProbability = 0.1;       % 10% packet loss probability

%% ============================================================
%  Section 4 : Flow Control Demo (Sliding Window)
% ============================================================
disp('========== TCP Flow Control (Sliding Window) ==========');
flowControl(totalPackets, windowSize);
disp('-------------------------------------------------------');
disp(' ');

%% ============================================================
%  Section 5 : TCP Transmission with Congestion Control
% ============================================================
disp('========== TCP Congestion Control + Transmission ==========');

sentPackets      = 0;
ackedPackets     = 0;
lostPackets      = 0;
roundNum         = 0;
cwndHistory      = [];   % cwnd value each round
ssthreshHistory  = [];   % ssthresh value each round
ackedHistory     = [];   % cumulative ACKed packets each round
lossHistory      = [];   % 1 = loss occurred, 0 = no loss
timeHistory      = [];   % round number

tic;   % Start timer

while ackedPackets < totalPackets

    roundNum = roundNum + 1;

    % Packets allowed by flow control AND congestion window
    packetsToSend = min([cwnd, windowSize, totalPackets - sentPackets]);

    if packetsToSend <= 0
        break;
    end

    disp(['Round ' num2str(roundNum) ' | cwnd = ' num2str(cwnd) ' | ssthresh = ' num2str(ssthresh)]);
    disp(['  Sending ' num2str(packetsToSend) ' packet(s)']);

    sentPackets = sentPackets + packetsToSend;

    % Simulate Packet Loss
    if rand() < lossProbability
        disp('  [!] Packet Loss Detected -> Reset to Slow Start');
        lostPackets = lostPackets + packetsToSend;
        ssthresh    = max(floor(cwnd / 2), 1);
        cwnd        = 1;
        lossHistory(end+1) = 1;   %#ok<AGROW>
    else
        ackedPackets = ackedPackets + packetsToSend;
        disp(['  ACK received for ' num2str(packetsToSend) ' packet(s) | Total ACKed = ' num2str(ackedPackets) ' / ' num2str(totalPackets)]);

        % Congestion Control Phase Decision
        if cwnd < ssthresh
            cwnd = cwnd * 2;
            disp(['  [Slow Start]           cwnd -> ' num2str(cwnd)]);
        else
            cwnd = cwnd + 1;
            disp(['  [Congestion Avoidance] cwnd -> ' num2str(cwnd)]);
        end
        lossHistory(end+1) = 0;   %#ok<AGROW>
    end

    % Record history for plotting
    cwndHistory     (end+1) = cwnd;           %#ok<AGROW>
    ssthreshHistory (end+1) = ssthresh;        %#ok<AGROW>
    ackedHistory    (end+1) = ackedPackets;    %#ok<AGROW>
    timeHistory     (end+1) = roundNum;

    % Simulate scaled propagation delay
    totalDelay = sum(linkDelays) / 1000;
    pause(totalDelay * 0.01);
end

totalTime = toc;   % Stop timer

%% ============================================================
%  Section 6 : Performance Evaluation
% ============================================================
totalDataBits  = ackedPackets * packetSize;
throughputBps  = totalDataBits / totalTime;
throughputMbps = throughputBps / 1e6;
packetLossRate = (lostPackets / sentPackets) * 100;

disp(' ');
disp('============ Performance Metrics ============');
disp(['Total Rounds             : ' num2str(roundNum)]);
disp(['Total Packets Sent       : ' num2str(sentPackets)]);
disp(['Total Packets ACKed      : ' num2str(ackedPackets)]);
disp(['Total Packets Lost       : ' num2str(lostPackets)]);
disp(['Packet Loss Rate         : ' num2str(packetLossRate, '%.2f') ' %']);
disp(['Total Transmission Time  : ' num2str(totalTime,      '%.4f') ' s']);
disp(['Throughput               : ' num2str(throughputMbps, '%.4f') ' Mbps']);
disp('---------------------------------------------');
disp(' ');

%% ============================================================
%  Section 7 : Visualization
% ============================================================

% --- Plot 1 : cwnd AND ssthresh — combined figure with two panels ---
figure('Name', 'TCP cwnd & ssthresh Dynamics', 'NumberTitle', 'off', ...
       'Position', [100, 100, 900, 620]);

% Pre-compute loss markers (used in both panels)
lossRounds = timeHistory(lossHistory == 1);
lossCwnd   = cwndHistory(lossHistory == 1);

% ---- Upper panel : cwnd vs ssthresh overlay ----
subplot(2, 1, 1);
hold on;

% Shaded area under cwnd curve
fill([timeHistory, fliplr(timeHistory)], ...
     [cwndHistory, zeros(1, length(cwndHistory))], ...
     [0.2 0.4 0.8], 'FaceAlpha', 0.12, 'EdgeColor', 'none', 'HandleVisibility', 'off');

% cwnd line
plot(timeHistory, cwndHistory, '-o', ...
     'LineWidth', 2, 'MarkerSize', 5, ...
     'Color', [0.2 0.4 0.8], ...
     'MarkerFaceColor', [0.2 0.4 0.8], ...
     'DisplayName', 'cwnd (Congestion Window)');

% ssthresh line
plot(timeHistory, ssthreshHistory, '--s', ...
     'LineWidth', 2, 'MarkerSize', 5, ...
     'Color', [0.8 0.3 0.1], ...
     'MarkerFaceColor', [0.8 0.3 0.1], ...
     'DisplayName', 'ssthresh (Slow-Start Threshold)');

% Loss events: red X markers + vertical dotted lines
if ~isempty(lossRounds)
    plot(lossRounds, lossCwnd, 'rx', ...
         'MarkerSize', 12, 'LineWidth', 3, ...
         'DisplayName', 'Packet Loss Event');
    for k = 1 : length(lossRounds)
        xline(lossRounds(k), ':', 'Color', [0.85 0 0], 'Alpha', 0.45, ...
              'HandleVisibility', 'off');
    end
end

% Phase labels: Slow Start before first ssthresh crossing, CA after
ssIdx = find(cwndHistory >= ssthreshHistory, 1, 'first');
yTop  = max(cwndHistory) * 0.88;
if ~isempty(ssIdx) && ssIdx > 1
    text(timeHistory(1) + 0.2, yTop, 'Slow Start', ...
         'FontSize', 9, 'FontAngle', 'italic', ...
         'Color', [0.1 0.3 0.75], 'FontWeight', 'bold');
    text(timeHistory(ssIdx) + 0.2, yTop, 'Congestion Avoidance', ...
         'FontSize', 9, 'FontAngle', 'italic', ...
         'Color', [0.1 0.55 0.15], 'FontWeight', 'bold');
end

hold off;
grid on;
title('TCP cwnd vs ssthresh — Slow Start & Congestion Avoidance Phases', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Transmission Round', 'FontSize', 11);
ylabel('Window Size (Packets)', 'FontSize', 11);
legend('Location', 'northwest', 'FontSize', 9);
xlim([1, max(timeHistory)]);

% ---- Lower panel : ssthresh evolution (staircase) showing each halving ----
subplot(2, 1, 2);
hold on;

% ssthresh as staircase — clearly shows the step-down at each loss
stairs(timeHistory, ssthreshHistory, '-', ...
       'LineWidth', 2.5, 'Color', [0.8 0.3 0.1], ...
       'DisplayName', 'ssthresh');

% cwnd overlaid as thin dotted reference
plot(timeHistory, cwndHistory, ':', ...
     'LineWidth', 1.5, 'Color', [0.2 0.4 0.8], ...
     'DisplayName', 'cwnd (reference)');

% Down-arrow marker at each halving event
if ~isempty(lossRounds)
    lossSSThresh = ssthreshHistory(lossHistory == 1);
    plot(lossRounds, lossSSThresh, 'v', ...
         'MarkerSize', 10, 'MarkerFaceColor', [0.85 0.1 0.1], ...
         'MarkerEdgeColor', [0.6 0 0], 'LineWidth', 1.5, ...
         'DisplayName', 'ssthresh halved  (cwnd/2)');
    % Annotate each halving with the new value
    for k = 1 : length(lossRounds)
        text(lossRounds(k) + 0.25, lossSSThresh(k) + 0.4, ...
             ['\leftarrow ' num2str(lossSSThresh(k))], ...
             'FontSize', 8.5, 'Color', [0.7 0 0]);
    end
end

hold off;
grid on;
title('ssthresh Evolution — Multiplicative Decrease at Each Loss Event (AIMD)', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Transmission Round', 'FontSize', 11);
ylabel('Threshold / Window (Packets)', 'FontSize', 11);
legend('Location', 'northeast', 'FontSize', 9);
xlim([1, max(timeHistory)]);

% --- Plot 2 : Cumulative ACKed Packets (actual tracker) ---
figure('Name', 'Cumulative Packets Acknowledged', 'NumberTitle', 'off');
plot(timeHistory, ackedHistory, '-s', 'LineWidth', 2, 'MarkerSize', 4, ...
     'Color', [0.1 0.6 0.3], 'MarkerFaceColor', [0.1 0.6 0.3]);
yline(totalPackets, '--r', 'LineWidth', 1.5, 'DisplayName', 'Target');
grid on;
title('Cumulative Packets Acknowledged Over Time', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Transmission Round',                       'FontSize', 12);
ylabel('Cumulative Packets Acknowledged',          'FontSize', 12);
legend({'ACKed Packets', 'Target (100)'}, 'Location', 'northwest');

% --- Plot 3 : Packet Summary Bar Chart ---
figure('Name', 'Performance Summary', 'NumberTitle', 'off');
values = [sentPackets, ackedPackets, lostPackets];
b = bar(values);
b.FaceColor = 'flat';
b.CData = [0.2 0.4 0.8; 0.1 0.6 0.3; 0.8 0.2 0.2];
set(gca, 'XTickLabel', {'Sent', 'ACKed', 'Lost'}, 'FontSize', 12);
title('Packet Transmission Summary', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Number of Packets',          'FontSize', 12);
grid on;

disp('Simulation complete. All figures displayed.');

%% ============================================================
%  Local Functions
% ============================================================

function status = tcpHandshake(sender, receiver)
% Simulates TCP Three-Way Handshake between sender and receiver nodes
    disp(['  Sender   Node (' num2str(sender)   ')  -->  SYN      -->  Receiver Node (' num2str(receiver) ')']);
    pause(0.2);
    disp(['  Receiver Node (' num2str(receiver) ')  -->  SYN-ACK  -->  Sender   Node (' num2str(sender)   ')']);
    pause(0.2);
    disp(['  Sender   Node (' num2str(sender)   ')  -->  ACK      -->  Receiver Node (' num2str(receiver) ')']);
    pause(0.2);
    status = 'Connection Established Successfully';
end

function flowControl(totalPackets, windowSize)
% Demonstrates sliding window flow control
    sentPackets  = 0;
    ackedPackets = 0;
    while ackedPackets < totalPackets
        packetsToSend = min(windowSize, totalPackets - sentPackets);
        disp(['  Sending ' num2str(packetsToSend) ' packet(s) | Window Size = ' num2str(windowSize)]);
        sentPackets  = sentPackets  + packetsToSend;
        ackedPackets = ackedPackets + packetsToSend;
        disp(['  ACK received for ' num2str(packetsToSend) ' packet(s) | Total ACKed = ' num2str(ackedPackets) ' / ' num2str(totalPackets)]);
        pause(0.05);
    end
    disp(['  All ' num2str(totalPackets) ' packets acknowledged via sliding window.']);
end