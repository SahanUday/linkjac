# IPv6 ranges that count as global but embed an IPv4 address or only mean something on a local network (linkding's list).
glob embedding_or_local: list[str] = ["64:ff9b::/96", "::/96", "fec0::/10"];

impl read_allow_list(text: str) -> AllowList {
    allowed = AllowList();
    for raw in text.split(",") {
        item = raw.strip().lower();
        if item == "*" {
            allowed.everything = True;
        } elif item {
            item = item.removeprefix("[").removesuffix("]");
            try {
                allowed.networks.append(ipaddress.ip_network(item, strict=False));
            } except ValueError {
                if "/" not in item {
                    allowed.host_names.append(item);
                }
            }
        }
    }
    return allowed;
}

def names_host(allowed: AllowList, host: str) -> bool {
    name = host.lower().rstrip(".");
    for each in allowed.host_names {
        if name == each or (each.startswith(".") and (name == each[1:] or name.endswith(each))) {
            return True;
        }
    }
    return False;
}

def covers_address(allowed: AllowList, address: str) -> bool {
    found = ipaddress.ip_address(address);
    if isinstance(found, IPv6Address) and found.ipv4_mapped is not None {
        found = found.ipv4_mapped;
    }
    return any([found in network for network in allowed.networks]);
}

impl is_public(address: str) -> bool {
    found = ipaddress.ip_address(address);
    if found.is_multicast {
        return False;
    }
    if any([found in ipaddress.ip_network(each) for each in embedding_or_local]) {
        return False;
    }
    return found.is_global;
}

impl checked_addresses(host: str, port: int) -> list[str] | None {
    allowed = read_allow_list(os.getenv("LD_ALLOWED_INTERNAL_HOSTS", ""));
    try {
        resolved = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM);
    } except (OSError, UnicodeError) {
        return None;
    }
    # A scoped address (fe80::1%eth0) is judged without its zone.
    addresses = [str(each[4][0]).split("%")[0] for each in resolved];
    if allowed.everything or names_host(allowed, host) {
        return addresses;
    }
    for address in addresses {
        if not covers_address(allowed, address) and not is_public(address) {
            return None;
        }
    }
    return addresses;
}
