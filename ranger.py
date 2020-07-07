#!/usr/bin/python3

import sys
import requests

class ranger:
    def __init__(self):
        self.option = sys.argv[1]
        self.timeout = float(sys.argv[2])
        self.up = 0

    def my_ip(self):
        r = requests.get("http://ipinfo.io/ip")
        self.host = (r.text).rstrip("\n")
        print("{+} my ip is "+self.host+"\n")
        return self

    def new_ip(self):
        para = self.host.split(".")
        if self.option == "24":
            self.new = para[0] + "." + para[1] + "." + para[2] + "."
            return self
        elif self.option == "16":
            self.new = para[0] + "." + para[1] + "."
            return self 
        else:
            print("specify 24 for class A or 16 for class B")
            sys.exit(1)

    def prober_c(self):
        for i in range(255):
            ip = "http://"+self.new+str(i)
            sys.stdout.write("\rtesting " + ip)
            sys.stdout.flush()                      
            try:
                r = requests.get(ip, timeout=self.timeout)
            except Exception:
                continue
            if r.status_code:
                self.up += 1
                print("\r>>> " + ip + " is up")
        return self.up

    def prober_b(self):
        for y in range(256):
            for x in range(255):
                ip = "http://"+self.new+str(y)+"."+str(x)
                sys.stdout.write("\rtesting " + ip)
                sys.stdout.flush()
                try:
                    r = requests.get(ip,timeout=self.timeout)
                except Exception:
                    continue
                else:
                    if r.status_code:
                        self.up += 1
                        print("\r>>> " + ip + " is up")
        return self.up

    def process(self):
        run.my_ip()
        run.new_ip()
        if self.option == "24":
            run.prober_c()
        elif self.option == "16":
            run.prober_b()
        print(f"\r#####Done! found {self.up} hosts up#####")

if __name__=="__main__":
    try:
        run = ranger()
    except Exception:
        print(f"usage: {sys.argv[0]} class(24 or 16) timeout(S)\n...ex: {sys.argv[0]} 24 2")
        sys.exit(1)
    run.process()