function [N_slots] = lwb_limits()

R = 250000;
N = 3;

H_max = [1:10];
L_pkt = [16 32 64 128 1 ];

% my_figfe(2);
% hold on
% colors = {'r','b','m','k'};
% styles = {'x','.','o','+'};
for i = 1:numel(L_pkt)
    T_tx = 8/R * L_pkt(i);
    T_slot = (H_max*T_tx + 2*(N-1)*T_tx)*1000; % to receive N times
%     plot(H_max,T_slot,'LineStyle',styles{i},'Color',colors{i})
end
% hold off
% xlabel('Maximum hop count');
% ylabel('Length of a slot [msec]');
% legend('16 bytes','32 bytes','64 bytes','128 bytes','Location','NorthWest');
% print_pdf('./t_slot.pdf');

T_gap = 4;
T_round = 1000;
T_scheduler_execution = 200;
L_schedule = 128;
L_cont_ack = 20;
N_schedule = 5;
T_tx_schedule = 8/R * L_schedule;
T_tx_cont_ack = 8/R * L_cont_ack;
T_schedule = (H_max*T_tx_schedule + 2*(N_schedule - 1)*T_tx_schedule)*1000;
T_cont_ack = (H_max*T_tx_cont_ack + 2*(N - 1)*T_tx_cont_ack)*1000;

N_slots = zeros(numel(L_pkt),numel(H_max));
for i = 1:numel(L_pkt)
    T_tx = 8/R * L_pkt(i);
    T_slot = (H_max*T_tx + 2*(N-1)*T_tx)*1000; % to receive N times
    for j = 1:numel(H_max)
        T_schedule = (H_max(j)*T_tx_schedule + 2*(N_schedule - 1)*T_tx_schedule)*1000;
        for k = 1:200
            rest = T_round - T_scheduler_execution - 2*T_schedule - 2*(T_cont_ack(j) + T_gap) - k*(T_slot(j) + T_gap);
            if rest < 0
                break;
            end
        end
        N_slots(i,j) = k - 1;
    end
end

end

% my_figfe(2);
% colormap(copper);
% bar(N_slots');
% xlabel('Maximum hop count');
% ylabel('Number of data slots per round');
% xlim([0.5 10.5]);
% legend('16 bytes','32 bytes','64 bytes','128 bytes');
% print_pdf('./slots_per_round.pdf');
