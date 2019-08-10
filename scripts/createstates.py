import os
import sys


def main(argv):
    with open('states.txt') as f:
        for line in f:
            os.system(f"touch {argv[1]}/{line.split()[1]}.gd")

if __name__ == '__main__':
    main(sys.argv) if len(sys.argv) > 1 else print("Please enter a file path")



            
