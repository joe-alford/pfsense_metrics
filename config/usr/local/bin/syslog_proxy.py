# This simple script it used to receive our syslog entries from pfSense, add `\n` to the end, and
# then send them on to Loki (running on Alloy). This is because of this bug: https://github.com/grafana/alloy/issues/560

# As a result, for every pfSense instance we wish to manage, we will need one of these proxys running, with a unique listening port.
# In the Alloy config, we will then have a unique `loki.source.syslog.listener` to which we forward these modified logs.

# See the files at /etc/systemd/system/syslog_proxy_****.service for an example of how to manage systemd services for them.

import socket
import argparse

def start_syslog_server(listen_port, forward_host, forward_port):
    # Create a UDP socket for receiving
    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_server_address = ('0.0.0.0', listen_port)
    recv_sock.bind(recv_server_address)
    print(f'Started syslog server on port {listen_port}')

    # Create a UDP socket for forwarding
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    forward_address = (forward_host, forward_port)

    while True:
        data, address = recv_sock.recvfrom(4096)
        if data:
            log_entry = data.decode('utf-8').strip() + '\n'
            print(f'Received log entry from {address}: {log_entry}')

            # Forward the log entry to the specified destination
            send_sock.sendto(log_entry.encode('utf-8'), forward_address)
            print(f'Forwarded log entry to {forward_address}')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Syslog server that appends newline to log entries and forwards them.')
    parser.add_argument('--listen-port', type=int, required=True, help='The port to listen on for syslog messages')
    parser.add_argument('--forward-host', type=str, required=True, help='The host to forward the log entries to')
    parser.add_argument('--forward-port', type=int, required=True, help='The port on the forward host to send the log entries to')
    args = parser.parse_args()

    start_syslog_server(args.listen_port, args.forward_host, args.forward_port)