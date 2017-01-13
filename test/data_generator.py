#!/usr/bin/python

import threading
import time
import sys
import random
import signal

class Generator(threading.Thread):
    def __init__(self, fname):
        threading.Thread.__init__(self)
        self.fname = fname
    def stop(self):
        self._is_running = False
    def run(self):
        self._is_running = True
        f = open(self.fname, "w")
        while self._is_running:
            time.sleep(random.random())
            ts = time.time()
            f.write("%s: %s %d %s\n" % (self.fname, time.ctime(ts), ts, "d"*500))
        f.close()

def stop_threads(threads):
    for t in threads:
        t.stop()
    for t in threads:
        t.join()

def main(argv):
    threads = [ Generator(fname) for fname in argv ]

    try:
        for t in threads:
            t.start()
    except:
        print "Error: unable to start thread"

    signal.signal(signal.SIGTERM, lambda x, y: stop_threads(threads))

    try:
        sys.stdin.readlines()
    except KeyboardInterrupt:
        print "Interrupt exception caught"
        stop_threads(threads)

if __name__ == "__main__":
    main(sys.argv[1:])
