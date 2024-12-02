#!/usr/bin/env python
import pandas as pd
import matplotlib.pyplot as plt
import argparse

parser=argparse.ArgumentParser(description="Plot scaling times")

parser.add_argument("--input",  required=True)
args=parser.parse_args()

fname = args.input

df = pd.read_csv(fname)

df['n'] = df.nx*df.ny*df.nz

fig, ax = plt.subplots()
ax.plot(df.n, df.time,'ro')

ax.set(ylabel='time (s)', 
       xlabel='MPI processes',
       title='Strong scaling')
ax.grid()

fig.savefig("times.png")
