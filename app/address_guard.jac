"""Address guard: which hosts a user's address may lead to, decided the way linkding decides it: public addresses and those an allow list names."""

import os;
import socket;
import ipaddress;
import from ipaddress { IPv4Address, IPv6Address, IPv4Network, IPv6Network }

"""What LD_ALLOWED_INTERNAL_HOSTS allows: everything, host names (a leading dot takes subdomains too) and address ranges."""
obj AllowList {
    has everything: bool = False,
        host_names: list[str] = [],
        networks: list[IPv4Network | IPv6Network] = [];
}

"""The allow list written as `text`: comma-separated names, addresses, ranges or `*`."""
def read_allow_list(text: str) -> AllowList;

"""Whether `address` is publicly routable."""
def is_public(address: str) -> bool;

"""The addresses a connection to `host` may be opened to, or None when the host may not be fetched from or does not resolve."""
def checked_addresses(host: str, port: int) -> list[str] | None;
