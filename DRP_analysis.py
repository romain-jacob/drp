"""
DRP-related analysis functions
"""

import os

import numpy as np
import pandas as pd
import plotly.graph_objects as go

import colors

# ==============================================================================
# DRP configuration parameters
# ==============================================================================
B = 5
r = 0.5
DRP_CONF_S_BOLT_PACK   = 590

# All time in [s]
DRP_CONF_C_WRITE       = 116*1e-6
DRP_CONF_C_READ        = 112*1e-6
DRP_CONF_C_FLUSH       = DRP_CONF_C_READ * DRP_CONF_S_BOLT_PACK
DRP_CONF_C_NET         = 1

DRP_CONF_TIME_FLUSH_CP = DRP_CONF_C_FLUSH + B * DRP_CONF_C_WRITE + DRP_CONF_C_NET
DRP_CONF_T_NET_MIN     = DRP_CONF_TIME_FLUSH_CP

DRP_CONF_DELTA_CONST_G = B * DRP_CONF_C_WRITE - (B - 1) * DRP_CONF_C_READ + DRP_CONF_C_FLUSH
DRP_CONF_DELTA_CONST_F = DRP_CONF_C_WRITE + DRP_CONF_C_FLUSH + DRP_CONF_TIME_FLUSH_CP
# ==============================================================================

def DRP_min_e2e_deadline():

    # Compute the min e
    Tfmin = 0.1;
    r = np.arange(0.1,1,0.01)
    y_source    = (2*DRP_CONF_T_NET_MIN+DRP_CONF_DELTA_CONST_F) /r
    y_dest      = ( Tfmin + DRP_CONF_DELTA_CONST_G)/(1 - r)

    y_max = np.maximum(y_source, y_dest)
    min_e2e_deadline = (Tfmin
                    + 2*DRP_CONF_T_NET_MIN
                    + DRP_CONF_DELTA_CONST_F
                    + DRP_CONF_DELTA_CONST_G)
    r_opt = (2*DRP_CONF_T_NET_MIN + DRP_CONF_DELTA_CONST_F) / min_e2e_deadline;

    # Plot
    fig = go.Figure()
    notes = []
    shapes = []

    # Admissible region
    fig.add_trace(
        go.Scatter(
            x=np.append(r,max(r)),
            y=np.append(y_max, max(y_max)),
            name='Admissible region',
            mode='none',
            fill='toself',
            fillcolor=colors.light_grey
        )
    )

    fig.add_trace(
        go.Scatter(
            x=r,
            y=y_source,
            name='(4.22) : Source constraint',
            line={'color':colors.blue,
                  'dash':'dash'},
        )
    )
    fig.add_trace(
        go.Scatter(
            x=r,
            y=y_dest,
            name='(4.21) : Dest. constraint',
            line={'color':colors.orange}
        )
    )

    # Smallest admissible end-to-end deadline
    # annot_text = ("Smallest admissible<br>end-to-end deadline<br><br>%0.2f s"
    #                 %  min_e2e_deadline )
    annot_text = ("Smallest admissible<br>end-to-end deadline<br><br>")
    annot_text += "<br>with r = %0.2f" % r_opt
    min_dead_annot = go.layout.Annotation(
            x=r_opt,
            y=min_e2e_deadline,
            xref="x",
            yref="y",
            text=annot_text,
            arrowhead=6,
            arrowwidth=1,
            arrowsize=2,
            ax=-350,
            ay=-75,
            bordercolor="black",
            borderpad=15,
            bgcolor=colors.light_orange,
            # showarrow=False,
            # xanchor='left'
        )
    notes.append(min_dead_annot)
    min_dead_value = go.layout.Annotation(
                x=r_opt,
                y=min_e2e_deadline,
                xref="x",
                yref="y",
                text="%0.2f s" % min_e2e_deadline,
                font={'size':22},
                ax=-350,
                ay=-63,
                showarrow=True,
                arrowcolor='rgba(255, 182, 193, .0)',
            )
    notes.append(min_dead_value)

    # y axis title
    ytitle = go.layout.Annotation(
            x=0,
            y=1.15,
            xref="paper",
            yref="paper",
            text="End-to-end deadline [s]",
            showarrow=False,
            xanchor='left'
        )
    notes.append(ytitle)

    default_layout = go.Layout(
        xaxis={'title':'Deadline ratio [ . ]',
               },
        # yaxis={'ticksuffix':"  "},
        annotations=notes,
        shapes=shapes,
        yaxis={'range':[0,max(y_max)]},
        legend={
            'bgcolor':'white',
            'xanchor':'right',
            'x':0.97,
            'yanchor':'top',
            'y':0.95,
            'borderwidth':5,
            'bordercolor':'white',
            }
        )
    fig.update_layout(default_layout)

    return fig

def dummy():
    print('DRP_CONF_T_NET_MIN : %f' % DRP_CONF_T_NET_MIN)

def DRP_process_latency(file_path):
    # Parse Flocklab serial file
    df = DRP_parse_flocklab(file_path)

    # Add the network deadline to the DataFrame
    e2e_deadlines = df['e2e_deadline[s]']
    periods       = df['period[s]']
    net_deadlines = []
    jitter        = 0
    for i in range(len(e2e_deadlines)):
        net_deadlines.append(calculate_net_deadline(periods[i], e2e_deadlines[i], jitter))
    df['net_deadline[s]'] = net_deadlines

    # Add the latency_bound to the DataFrame
    min_e2e_deadline = df['e2e_deadline[s]'].min()
    latency_bounds = []
    for i in range(len(e2e_deadlines)):
        latency_bounds.append(calculate_latency_bound(periods[i], net_deadlines[i], min_e2e_deadline))
    df['latency_bound[s]'] = latency_bounds

    # Compute the latency ratio
    df['tightness[%]'] = df['latency[s]'] / df['latency_bound[s]'] * 100

    # Reorder columns and save to csv
    df_ordered = df[['flowID',
                     'src',
                     'dest',
                     'period[s]',
                     'e2e_deadline[s]',
                     'net_deadline[s]',
                     'latency_bound[s]',
                     'seqn',
                     'send_ts[s]',
                     'rcv_ts[s]',
                     'latency[s]',
                     'slack[s]',
                     'tightness[%]'
                     ]]
    out_file = str(file_path / 'flow_data.csv')
    df_ordered.to_csv(path_or_buf=out_file, index=False)

    # Plot the correct ratio
    figure = DRP_hist(df['tightness[%]'])
    
    # Compute packet reception ratio
    PRR = df.count()['rcv_ts[s]'] / df.count()['send_ts[s]'] *100
    
    return df_ordered, figure, PRR

def calculate_latency_bound(period, net_deadline, min_e2e_deadline):
    """
    Compute the upper-bound on expected latency, for a flow given
    - the flow period (in seconds)
    - the flow network deadline (in seconds)
    - the minimal end-to-end deadline of the flows registered at the destination (in seconds)
    """
    latency_bound = (DRP_CONF_C_WRITE + DRP_CONF_C_FLUSH + DRP_CONF_TIME_FLUSH_CP
                   + period + net_deadline
                   + B * DRP_CONF_C_WRITE
                   - (B - 1) * DRP_CONF_C_READ
                   + DRP_CONF_C_FLUSH
                   + (1 - r) * (min_e2e_deadline) - DRP_CONF_DELTA_CONST_G)

    return latency_bound


def calculate_net_deadline(period, e2e_deadline, jitter):
    net_deadline = min( period,
                        e2e_deadline * r - DRP_CONF_DELTA_CONST_F
                        - period - jitter);

    if (net_deadline < DRP_CONF_T_NET_MIN):
        net_deadline = DRP_CONF_T_NET_MIN
    elif (net_deadline > period):
        net_deadline = period

    # Floor network deadline to a multiple of the round time
    net_deadline = net_deadline - (net_deadline % DRP_CONF_T_NET_MIN)

    return net_deadline


def DRP_parse_flocklab(file_path):

    HOST_ID = 1
    SOURCE_IDs = [3, 4, 6, 8, 15, 22, 28, 31, 32, 33]

    data_file           = file_path / 'serial.csv'
    data_file_pruned    = file_path / 'serial_DATA.csv'

    # Prun the file
    os.system("sed '/DATA/!d' %s > %s" % (data_file,data_file_pruned))

    # Open the test serial log
    f = open( data_file_pruned , "r")

    # Get the first timestamp
    line = f.readline()
    time_ref = float(line[0:-1].split(',')[0])
    f.seek(0, 0)

    # Data storage
    snd_packet = []
    rcv_packet = []

    ##
    # PACKET SENT
    ##

    # Loop through the list of nodes
    for node_id in SOURCE_IDs:

        # Re-start reading the serial file from the top
        f.seek(0, 0)

        # Read serial log first line
        line = f.readline()
        while line != '':

            if ('%u,%u,' % (node_id,node_id)) in line:
                # Extract the relevant info
                tmp = line[0:-1].split(',')
                send_ts = float(tmp[0])-time_ref
                dest = 1
                flowID = ('%u-%u' % (node_id, dest))

                tmp = tmp[5].split(' ')
                seqn = int(tmp[2])
                period = float(tmp[5])/1000

                # Store send packet data
                snd_packet.append([flowID, node_id, dest, seqn, period, send_ts])

                # if 'packet 0' in line:
                #     print(tmp)
                    # print(send_ts,dest,flowID,seqn,e2e_deadline)

            # Read the next lime
            line = f.readline()

    df_sent = pd.DataFrame(snd_packet, columns=['flowID', 'src', 'dest', 'seqn', 'period[s]', 'send_ts[s]'])

    ##
    # PACKETS RECEIVED
    ##

    # Loop through the list of nodes
    for node_id in SOURCE_IDs:

        # Re-start reading the serial file from the top
        f.seek(0, 0)

        # Read serial log first line
        line = f.readline()
        while line != '':

            if '1,1,' in line and ('Node %u,' % node_id) in line:
                # Extract the relevant info
                tmp = line[0:-1].split(',')
                rcv_ts = float(tmp[0])-time_ref
                dest = 1

                tmp = tmp[5].split(' ')
                seqn = int(tmp[2])
                e2e_deadline = float(tmp[5])/1000

                # Store send packet data
                rcv_packet.append([node_id, dest, seqn, e2e_deadline, rcv_ts])

                # if 'packet 0' in line:
                #     print(tmp)
                    # print(send_ts,dest,flowID,seqn,e2e_deadline)

            # Read the next lime
            line = f.readline()

    f.close()
    # print(snd_packet)
    df_rcv = pd.DataFrame(rcv_packet, columns=['src', 'dest', 'seqn', 'e2e_deadline[s]', 'rcv_ts[s]'])

    # Combine DataFrames
    df = df_sent.merge(df_rcv, how='outer')

    # Correct the time offsets
    offset = df['send_ts[s]'].min()
    df['send_ts[s]'] = df['send_ts[s]'] - offset
    df['rcv_ts[s]']  = df['rcv_ts[s]'] - offset

    # Compute the latency
    df['latency[s]'] = df['rcv_ts[s]'] - df['send_ts[s]']

    # Compute slack ratio
    df['slack[s]'] = df['e2e_deadline[s]'] - df['latency[s]']

    # Fill the missing e2e_deadline values
    tmp = df["e2e_deadline[s]"].fillna(method='bfill')
    df["e2e_deadline[s]"] = tmp
    return df

# =================================================================================================

def DRP_hist(x, annot_size=16):

    # Vertical positioning of annotations
    top_annot = 0.95
    second_annot = 0.75

    max_latency_ratio = max(x)

    fig = go.Figure()

    fig.add_trace(
        go.Histogram(
            x=x,
            histnorm='percent',
            nbinsx=50,
            marker_color=colors.light_orange,
        )
    )

    notes = []
    shapes = []

    # Analytical bound
    note = go.layout.Annotation(
            x=100,
            y=top_annot,
            xref="x",
            yref="paper",
            text="Analytical bound",
            showarrow=False,
            # font=dict(
            #     size=annot_size,
            # ),
            xanchor='right',
            xshift=-10
        )
    notes.append(note)
    line = go.layout.Shape(
            type="line",
            xref="x",
            x0=100,
            x1=100,
            yref="paper",
            y0=0,
            y1=top_annot,
            line=dict(
                color=colors.red,
                width=3,
            )
        )
    shapes.append(line)

    # Reached bound
    note = go.layout.Annotation(
            x=max_latency_ratio,
            y=second_annot,
            xref="x",
            yref="paper",
            text=("%2.0f%%" % max_latency_ratio),
            showarrow=False,
            # font=dict(
            #     size=annot_size,
            # ),
            xanchor='right',
            xshift=-10
        )
    notes.append(note)
    line = go.layout.Shape(
            type="line",
            xref="x",
            x0=max_latency_ratio,
            x1=max_latency_ratio,
            yref="paper",
            y0=0,
            y1=second_annot,
            line=dict(
                color=colors.red,
                width=3,
                dash="dot",
            )
        )
    shapes.append(line)

    ytitle = go.layout.Annotation(
            x=0,
            y=1.25,
            xref="paper",
            yref="paper",
            text="Percentage of messages [%]",
            showarrow=False,
            xanchor='left',
        )
    notes.append(ytitle)

    # Default Layout
    default_layout = go.Layout(
        xaxis={'title':'End-to-end latency of messages  [ % of analytic bound ]',
               'range':[-1,105],
               'zeroline':True
               },
        yaxis={'ticksuffix':"  ",'zeroline':True},
        annotations=notes,
        shapes=shapes,
        )
    fig.update_layout(default_layout)

    return fig
