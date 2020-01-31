#!/usr/bin/env python

"""
Dotfiles restore
Restores files from backup into home.

Optional arguments:
--home     - Path to home directory (default: $HOME)
--backup   - Path to backup directory (default: ~/.dotfiles/backup)
"""

from __future__ import print_function
from builtins import input

import os
import shutil
import argparse

# Globals
DOTFILES_DIR = os.path.dirname(os.path.abspath(__file__))

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--home',
        dest='home_dir',
        default=os.path.expanduser('~'),
        help="path to target directory (default: $HOME)")
    parser.add_argument('--backup',
        dest='backup_dir',
        default=os.path.join(DOTFILES_DIR,'backup'),
        help="path to backup directory (default: ~/.dotfiles/backup)")
    return parser.parse_args()

def force_remove(path):
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path, False)
    else:
        os.unlink(path)

def copy(path, dest):
    if os.path.isdir(path):
        shutil.copytree(path, dest)
    else:
        shutil.copy(path, dest)

def main():
    # Get input arguments
    args = parse_args()

    # Check if backup exists
    if not os.path.exists(args.backup_dir):
        print("Backup directory '{}' does not exists!".format(args.backup_dir))
        return

    # Restore dotfiles from backup
    for filename in os.listdir(args.backup_dir):
        dotfile = os.path.join(args.backup_dir, filename)
        dest = os.path.join(args.home_dir, filename)
        force_remove(dest)
        copy(dotfile, dest)
        force_remove(dotfile)
        print("'{}' has been restored!".format(dest))

if __name__ == '__main__':
    main()
