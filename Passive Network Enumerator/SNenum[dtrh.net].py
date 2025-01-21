#!/usr/bin/env python3
"""
Refactored network sniffer that polls for results, displays them in a Rich table,
and optionally exports them to CSV or PCAP. Includes option for filtering in context
of host -c --context 

WORK IN PROGRESS
"""

import argparse
import sys
import logging
import csv
import threading
import queue
import platform
import signal
import os
import subprocess
import re

from collections import defaultdict
from scapy.all import (
    sniff,
    IP,
    TCP,
    UDP,
    IPv6,
    conf,
    get_if_addr,
    get_if_list,
    get_working_if,
    wrpcap
)
from rich.console import Console
from rich.table import Table

# ================================================================
# GLOBALS
# ================================================================
v4_data = defaultdict(lambda: {"TCP": set(), "UDP": set()})
v6_data = defaultdict(lambda: {"TCP": set(), "UDP": set()})

packet_queue = queue.Queue()       # Communication channel from sniffer -> main loop
stop_event = threading.Event()     # Signals the sniffer thread to stop
raw_packets = []                   # If user requests pcap, store raw packets here
console = Console()

# ================================================================
# SIGNAL HANDLING
# ================================================================
def signal_handler(sig, frame):
    """
    Gracefully handle Ctrl+C (SIGINT) to stop sniffing and clean up resources.
    """
    print("\n[INFO] Caught Ctrl+C. Stopping sniff and exiting...")
    stop_event.set()
    console.clear()
    # We use os._exit(0) to force immediate exit without extra traceback.
    # Alternatively: sys.exit(0), but that can sometimes raise exceptions in threads.
    os._exit(0)

signal.signal(signal.SIGINT, signal_handler)

# ================================================================
# ARGUMENT PARSING
# ================================================================
def parse_args():
    """
    Parses arguments for interface, IPv4/IPv6 toggles, CSV/PCAP logging, and context IP.
    """
    parser = argparse.ArgumentParser(description="A cross-platform network traffic sniffer.")
    parser.add_argument("-i", "--interface", help="Network interface to sniff on (e.g., eth0, wlan0).")
    # We now allow specifying either or neither. If both are used => error.
    parser.add_argument("-4", "--ipv4", action="store_true", help="Capture only IPv4 traffic.")
    parser.add_argument("-6", "--ipv6", action="store_true", help="Capture only IPv6 traffic.")
    parser.add_argument("-l", "--log", nargs='?', const='traffic_log.csv', help="Export data to CSV. "
                        "If used with no argument, defaults to 'traffic_log.csv'.")
    parser.add_argument("-R", "--raw", nargs='?', const='raw_capture.pcap', help="Save raw packets to PCAP. "
                        "If used with no argument, defaults to 'raw_capture.pcap'.")
    parser.add_argument("-c", "--context", help="Specify a target IP for contextual focus (default: gateway).")

    args = parser.parse_args()
    
    # Disallow both --ipv4 and --ipv6 simultaneously if that’s your desired policy:
    if args.ipv4 and args.ipv6:
        parser.error("Cannot specify both --ipv4 and --ipv6 together. Choose one.")

    return args

# ================================================================
# OS & PRIVILEGE CHECK
# ================================================================
def check_os_compatibility():
    os_type = platform.system().lower()
    if os_type.startswith("win"):
        print("[INFO] Detected Windows OS. Ensure Npcap is installed.")
    elif os_type.startswith("linux"):
        # On Linux, you typically need root privileges to sniff
        if os.geteuid() != 0:
            print("[ERROR] Root privileges required for packet capture on Linux.")
            sys.exit(1)
    return os_type

# ================================================================
# NETWORK HELPERS
# ================================================================
def guess_interface():
    """
    Attempt to determine a valid network interface.
    """
    try:
        if conf.iface:
            print(f"[INFO] Using default Scapy interface: {conf.iface}")
            return conf.iface

        w_if = get_working_if()
        if w_if:
            print(f"[INFO] Detected working interface via Scapy: {w_if}")
            return w_if

        available_ifaces = get_if_list()
        if available_ifaces:
            print(f"[INFO] Available interfaces: {', '.join(available_ifaces)}")
            return available_ifaces[0]

        print("[ERROR] No network interfaces found.")
        return None
    except Exception as e:
        print(f"[ERROR] Failed to detect a network interface: {e}")
        return None

def get_default_gateway():
    """
    Retrieve the default gateway IP of the current system. On success,
    return the gateway IP, else return "Unknown".
    """
    os_type = platform.system().lower()
    gateway_ip = None

    try:
        if os_type.startswith("win"):
            result = subprocess.check_output("ipconfig", encoding='utf-8')
            match = re.search(r"Default Gateway[.\s]*:\s*(\d+\.\d+\.\d+\.\d+)", result)
            if match:
                gateway_ip = match.group(1)
        else:
            # For Linux or macOS, try "ip route" first, fallback to "netstat -rn"
            try:
                result = subprocess.check_output("ip route", shell=True, encoding='utf-8')
                match = re.search(r"default via (\d+\.\d+\.\d+\.\d+)", result)
                if match:
                    gateway_ip = match.group(1)
            except:
                # Fallback to netstat -rn
                result = subprocess.check_output("netstat -rn", shell=True, encoding='utf-8')
                # For macOS or older systems, 'default' might appear differently
                match = re.search(r"default\s+(\d+\.\d+\.\d+\.\d+)", result)
                if match:
                    gateway_ip = match.group(1)
    except Exception as e:
        print(f"[ERROR] Unable to determine default gateway: {e}")

    return gateway_ip or "Unknown"

# ================================================================
# PACKET PROCESSING
# ================================================================
def handle_packet(packet, ip_version):
    """
    Store the TCP/UDP dst port in v4_data or v6_data.
    This does not filter specifically by a 'context IP'; it simply records all local traffic.
    If you want to filter by context_ip (e.g. only store if src/dst == context_ip),
    you could add that logic here.
    """
    try:
        if ip_version == "IPv4" and IP in packet:
            dst_ip = packet[IP].dst
            if TCP in packet:
                v4_data[dst_ip]["TCP"].add(packet[TCP].dport)
            elif UDP in packet:
                v4_data[dst_ip]["UDP"].add(packet[UDP].dport)

        elif ip_version == "IPv6" and IPv6 in packet:
            dst_ip = packet[IPv6].dst
            if TCP in packet:
                v6_data[dst_ip]["TCP"].add(packet[TCP].dport)
            elif UDP in packet:
                v6_data[dst_ip]["UDP"].add(packet[UDP].dport)

    except Exception as e:
        print(f"[ERROR] Failed to process {ip_version} packet: {e}")

def packet_callback(packet, capture_ipv4=True, capture_ipv6=True, capture_raw=False):
    """
    Called by Scapy's sniff() for each captured packet.
    - If capture_raw is True, store full packet in raw_packets.
    - If IPv4 or IPv6 is enabled, call handle_packet() and add an 'update' event to packet_queue.
    """
    if capture_raw:
        raw_packets.append(packet)

    # If user wants IPv4 only
    if capture_ipv4 and IP in packet:
        handle_packet(packet, "IPv4")
        packet_queue.put("update")

    # If user wants IPv6 only
    elif capture_ipv6 and IPv6 in packet:
        handle_packet(packet, "IPv6")
        packet_queue.put("update")

# ================================================================
# TABLE DISPLAY
# ================================================================
def create_table(data, title):
    """
    Creates a Rich table for either v4_data or v6_data.
    'data' is a dict of { ip: { 'TCP': set(), 'UDP': set() }, ... }
    """
    table = Table(title=title, style="bold white")
    table.add_column("IP Address", style="white")
    table.add_column("Protocol", style="grey66")
    table.add_column("Ports", style="grey66")

    for ip_addr, proto_dict in data.items():
        for protocol, ports in proto_dict.items():
            if ports:
                sorted_ports = sorted(ports)
                table.add_row(ip_addr, protocol, ",".join(str(p) for p in sorted_ports))
    return table

def redraw_tables(context_ip):
    """
    Clears the console, prints a heading with context IP,
    and prints both IPv4 and IPv6 tables.
    """
    console.clear()
    console.print(f"[bold white]\nTraffic in Context: {context_ip}[/bold white]")
    ipv4_table = create_table(v4_data, "IPv4 Traffic")
    ipv6_table = create_table(v6_data, "IPv6 Traffic")
    console.print(ipv4_table)
    console.print(ipv6_table)

# ================================================================
# CSV EXPORT
# ================================================================
def export_to_csv(csv_filename):
    """
    Exports all v4_data and v6_data to CSV. Each row: IP, Protocol, Ports
    """
    print(f"[INFO] Exporting data to '{csv_filename}'...")
    try:
        with open(csv_filename, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(["IP Address", "Protocol", "Ports"])

            # IPv4
            for ip_addr, proto_dict in v4_data.items():
                if proto_dict["TCP"]:
                    writer.writerow([
                        ip_addr,
                        "TCP",
                        ",".join(str(p) for p in sorted(proto_dict["TCP"]))
                    ])
                if proto_dict["UDP"]:
                    writer.writerow([
                        ip_addr,
                        "UDP",
                        ",".join(str(p) for p in sorted(proto_dict["UDP"]))
                    ])

            # IPv6
            for ip_addr, proto_dict in v6_data.items():
                if proto_dict["TCP"]:
                    writer.writerow([
                        ip_addr,
                        "TCP",
                        ",".join(str(p) for p in sorted(proto_dict["TCP"]))
                    ])
                if proto_dict["UDP"]:
                    writer.writerow([
                        ip_addr,
                        "UDP",
                        ",".join(str(p) for p in sorted(proto_dict["UDP"]))
                    ])
        print(f"[INFO] Finished writing to '{csv_filename}'.")
    except Exception as e:
        print(f"[ERROR] Failed to write CSV file '{csv_filename}': {e}")

# ================================================================
# BACKGROUND SNIFFER THREAD
# ================================================================
def sniff_thread_func(iface, capture_ipv4, capture_ipv6, capture_raw):
    """
    Continuously sniffs on the selected interface using scapy's sniff().
    We use a small timeout so we can periodically check the stop_event.
    """
    # We'll sniff in a loop with short timeouts, so we can stop gracefully.
    while not stop_event.is_set():
        sniff(
            iface=iface,
            prn=lambda pkt: packet_callback(pkt, capture_ipv4, capture_ipv6, capture_raw),
            store=False,
            timeout=1
        )

# ================================================================
# MAIN
# ================================================================
def main():
    args = parse_args()
    os_type = check_os_compatibility()

    # Decide which interface to use
    iface = args.interface if args.interface else guess_interface()
    if not iface:
        sys.exit("[ERROR] No interface specified or detected.")

    # Decide if user wants IPv4, IPv6, or both
    if not args.ipv4 and not args.ipv6:
        # If neither -4 nor -6 is specified, capture both by default
        capture_ipv4, capture_ipv6 = True, True
    else:
        # If user specified one of them, do exactly that
        capture_ipv4 = args.ipv4
        capture_ipv6 = args.ipv6

    # Determine if user wants raw PCAP
    capture_raw = False
    pcap_filename = None
    if args.raw is not None:
        capture_raw = True
        pcap_filename = args.raw
        if pcap_filename == 'raw_capture.pcap':
            pcap_filename = 'raw_capture.pcap'
        elif not pcap_filename.endswith(".pcap"):
            pcap_filename += ".pcap"
        print(f"[INFO] Raw packet capture enabled. Will save to '{pcap_filename}'.")

    # Determine CSV filename if user wants logging
    csv_filename = None
    if args.log is not None:
        csv_filename = args.log
        if csv_filename == 'traffic_log.csv':
            csv_filename = 'traffic_log.csv'
        elif not csv_filename.endswith(".csv"):
            csv_filename += ".csv"
        print(f"[INFO] Final CSV export will be '{csv_filename}' at exit.")

    # Decide context IP (default gateway or user-provided)
    context_ip = args.context if args.context else get_default_gateway()
    print(f"[INFO] Context IP: {context_ip}")
    print(f"[INFO] Using interface '{iface}' for sniffing...")

    # Start the background sniffing thread
    sniffer = threading.Thread(
        target=sniff_thread_func,
        args=(iface, capture_ipv4, capture_ipv6, capture_raw),
        daemon=True
    )
    sniffer.start()
    print("[INFO] Sniffing in the background. Press Ctrl+C to stop.\n")

    # Main loop: wait for updates from the sniff thread
    try:
        while not stop_event.is_set():
            try:
                packet_queue.get(timeout=1)
                # On 'update', redraw the tables
                redraw_tables(context_ip)
            except queue.Empty:
                pass
    except KeyboardInterrupt:
        # If we missed the signal in the thread, handle it here
        print("\n[INFO] Caught Ctrl+C in main. Stopping.")
        stop_event.set()

    # Wait for sniffer thread to end
    sniffer.join(timeout=2)

    # Export to CSV if requested
    if csv_filename:
        export_to_csv(csv_filename)

    # Export raw PCAP if requested
    if capture_raw and pcap_filename:
        try:
            wrpcap(pcap_filename, raw_packets)
            print(f"[INFO] Raw PCAP saved to '{pcap_filename}'.")
        except Exception as e:
            print(f"[ERROR] Failed to write PCAP '{pcap_filename}': {e}")

    print("[INFO] Exiting.")
    sys.exit(0)


if __name__ == "__main__":
    main()
