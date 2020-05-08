#!/usr/bin/env python

# This Python script counts the lines of code in the directory in which it is
# run.  It only looks at files which end in the file extensions passed to the
# script as arguments.

# It outputs counts for total lines, blank lines, comment lines and code lines
# (total lines minus blank lines and comment lines).

# Example usage and output:
# > lines_of_code_counter.py .h .cpp --loc "src;include"
# Total lines:   15378
# Blank lines:   2945
# Comment lines: 1770
# Code lines:    10663

# Change this value based on the comment symbol used in your programming
# language.
import os
import os.path
import pathlib
import logging

COMMENT_SYMBOLS = ("/*", "//", "<!--", "#", '--')
C_FILE_EXTENSIONS = ('.c', '.h', 'cpp', '.hpp', '.cxx')
PY_FILE_EXTENSIONS = ('.py', '.rst')
VHDL_FILE_EXTENSIONS = ('.vhd', '.vhdl')
WEB_FILE_EXTENSIONS = ('.js', '.css', '.html')
CSHARP_FILE_EXTENSIONS = ('.cs', '.xaml')
UTIL_EXTENSIONS = ('.cmake', '.sh', '.bat', '.ps', '.tex')
ALL_FILE_EXTENSIONS = set().union(C_FILE_EXTENSIONS, PY_FILE_EXTENSIONS, CSHARP_FILE_EXTENSIONS, UTIL_EXTENSIONS, VHDL_FILE_EXTENSIONS)

LANGUAGE_COMMENT_SYMBOLS = {

    '.c': ['//', '/*'],
    '.h': ['//', '/*'],
    '.cpp': ['//', '/*'],
    '.hpp': ['//', '/*'],
    
    '.vhd': ['--'],
    '.vhdl': ['--'],
    
    '.py': ['#'],

    '.xml': ['<!--'],
    '.html': ['<!--'],
    '.css' : ['/*'],
    '.js' : ['/*', '//'],

    # Other
    '.tex' : ['%'],
    '.sh' : ['#'],
    '.bat' : ['#'],
    '.cmake' : ['#'],
}

def verbose_print(verbose, *args):
    if verbose:
        print(*args)

def is_line_starting_with_comment(filename: str, line:str) -> bool:

    # Get extension
    file_extension = str(pathlib.Path(filename).suffix)
    
    # Try to look up:
    try:
        comment_symbols = tuple(LANGUAGE_COMMENT_SYMBOLS[file_extension])
    except KeyError as keyError:
        logging.warning(msg=f'No comment symbols specified for "{file_extension}"')
        return False
    


    return line.startswith(comment_symbols)  



def count_lines(directories, acceptable_file_extensions=ALL_FILE_EXTENSIONS, verbose=False):


    verbose_print(verbose, "Checking folders:")
    verbose_print(verbose, directories)

    current_dir = os.getcwd()

    files_to_check = []
    # for root, _, files in os.walk(current_dir):
    for scan_folder in directories:
        for root, _, files in os.walk(scan_folder):
            for f in files:
                full_path = os.path.join(root, f)
                if '.git' not in full_path:
                    for extension in acceptable_file_extensions:
                        if full_path.endswith(extension):
                            files_to_check.append(full_path)

    if not files_to_check:
        print('No files found.')
        return

    line_count = 0
    total_blank_line_count = 0
    total_comment_line_count = 0

    print('')
    print('Filename\tlines\tblank lines\tcomment lines\tcode lines')

    for fileToCheck in files_to_check:
        with open(fileToCheck) as f:

            file_line_count = 0
            file_blank_line_count = 0
            file_comment_line_count = 0

            for line in f:
                line_count += 1
                file_line_count += 1
                line_without_whitespace = line.strip()
                if not line_without_whitespace:
                    total_blank_line_count += 1
                    file_blank_line_count += 1
                # elif line_without_whitespace.startswith(COMMENT_SYMBOLS):  # ToDo
                elif is_line_starting_with_comment(filename=fileToCheck, line=line):
                    total_comment_line_count += 1
                    file_comment_line_count += 1

            print(os.path.basename(fileToCheck) +
                  "\t" + str(file_line_count) +
                  "\t" + str(file_blank_line_count) +
                  "\t" + str(file_comment_line_count) +
                  "\t" + str(file_line_count - file_blank_line_count - file_comment_line_count))

    print('')
    print('Totals')
    print('--------------------')
    print('Lines:         ' + str(line_count))
    print('Blank lines:   ' + str(total_blank_line_count))
    print('Comment lines: ' + str(total_comment_line_count))
    print('Code lines:    ' + str(line_count - total_blank_line_count - total_comment_line_count))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--loc", help="Specify folder locations, splittable via ';'", default=".")
    parser.add_argument("--ext", help="Specify file extensions", nargs='+')
    parser.add_argument("-v", "--verbose", help="increase output verbosity",
                        action="store_true")

    args = parser.parse_args(args=['--loc', 'python'])
    print(args)

    folders = args.loc
    acceptableFileExtensions = args.ext

    # Spit and strip whitespaces
    folders = folders.split(";")
    folders = [folder.strip() for folder in folders]

    count_lines(folders)
