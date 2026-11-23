"""Command line: the admin commands (import and export of Netscape files), each one a call to the server."""

import sys;
import from stdjac { RemoteError }

"""What the command line asks for: the command and the words after it."""
def usage -> str;

"""Read a Netscape file and send it to the server; prints the counts."""
def run_import(path: str, map_private_flag: bool) -> int;

"""Write the server's Netscape export to `path`, or to the screen when there is no path."""
def run_export(path: str) -> int;

"""Run the command the arguments name and return the exit status."""
def run_command(args: list[str]) -> int;

with entry {
    sys.exit(run_command(sys.argv[1:]));
}
