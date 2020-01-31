#!/usr/bin/env python

"""
Dotfiles synchronization.
Creates symlinks for all dotfiles

Optional arguments
------------------
-f --force - Never prompt and overwrite files
--home     - Path to home directory (default: $HOME)
--config   - Path to config directory (default: ~/.dotfiles/config)
--backup   - Path to backup directory (default: ~/.dotfiles/backup)
--exlude   - List of exluded files from synchronization.
"""

from __future__ import print_function
from builtins import input

import os
import sys
import glob
import shutil
import argparse

# Globals
DOTFILES_DIR = os.path.dirname(os.path.abspath(__file__))

def parse_args():
    """ Parse optional input arguments"""

    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--force',
        action='store_true',
        help="never prompt and overwrite files")
    parser.add_argument('--home',
        dest='home_dir',
        default=os.path.expanduser('~'),
        help="path to home directory (default: $HOME)")
    parser.add_argument('--config',
        dest='config_dir',
        default=os.path.join(DOTFILES_DIR, 'config'),
        help="path to config directory (default: dotfiles/config)")
    parser.add_argument('--backup',
        dest='backup_dir',
        default=os.path.join(DOTFILES_DIR,'backup'),
        help="path to backup directory (default: dotfiles/backup)")
    parser.add_argument('--exclude',
        dest='exclude',
        default=[],
        nargs='+',
        help="list of excluded files from synchronization")
    return parser.parse_args()

def force_remove(path):
    """ Remove symlink or directory"""

    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path, False)
    else:
        os.unlink(path)

def is_link_to(link, dest):
    """ Check if link points to destination """

    return os.path.islink(link) and os.readlink(link).rstrip('/') == dest.rstrip('/')

def copy(src, dest):
    """ Copy file from source to destination """

    if os.path.isdir(src):
        shutil.copytree(src, dest)
    else:
        shutil.copy(src, dest)

def backup(path, backup_dir):
    """ Backup file to backup_dir """

    if not os.path.exists(backup_dir):
        os.mkdir(backup_dir)

    backup = os.path.join(backup_dir, os.path.basename(path))
    copy(path, backup)

def main():
    args = parse_args()

    for filename in [file for file in os.listdir(args.config_dir) if file not in args.exclude]:
        dotfile = os.path.join(args.home_dir, filename)
        source = os.path.relpath(os.path.join(args.config_dir, filename), args.home_dir)

        # Check that dotfile already exists
        if not os.path.exists(dotfile):
            continue

        # Check if file is already symlinked
        if is_link_to(dotfile, source):
            continue

        # On force automatically backup otherwise ask user
        if args.force:
            backup(dotfile, args.backup_dir)
        else:
            # Ask user if he wants to overwrite
            res = input("Overwrite file '{}'? [y/N] ".format(dotfile))
            if not res.lower().startswith('y'):
                print("Skipping '{}'...".format(dotfile))
                continue

            # Ask user if he wants to backup copy if we're overwriting this file
            res = input("Backup file '{}'? [y/N] ".format(dotfile))
            if res.lower().startswith('y'):
                backup(dotfile, args.backup_dir)

        # Remove current file and make symlink
        force_remove(dotfile)
        os.symlink(source, dotfile)
        print("{} => {}".format(dotfile, source))

if __name__ == '__main__':
    main()
