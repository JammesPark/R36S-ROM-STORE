"""HTTP local: interromper curl sem apagar bytes e retomar via Range."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import signal
import subprocess
import tempfile
import threading
import time

DATA=bytes(range(256))*4096
RANGES=[]
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_GET(self):
        start=0
        header=self.headers.get("Range")
        if header:
            start=int(header.split("=")[1].split("-")[0])
            RANGES.append(start)
        self.send_response(206 if header else 200)
        self.send_header("Content-Length",str(len(DATA)-start))
        self.send_header("Accept-Ranges","bytes")
        if header:
            self.send_header("Content-Range",f"bytes {start}-{len(DATA)-1}/{len(DATA)}")
        self.end_headers()
        try:
            for i in range(start,len(DATA),8192):
                self.wfile.write(DATA[i:i+8192]);self.wfile.flush()
                time.sleep(0.003)
        except (BrokenPipeError,ConnectionResetError): pass

server=ThreadingHTTPServer(("127.0.0.1",0),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
    with tempfile.TemporaryDirectory() as td:
        base=Path(td)
        part,pid,rc,stop=[base/n for n in ("part","pid","rc","stop")]
        cmd=["sh","r36sromsstore/bin/fetch.sh","get",f"http://127.0.0.1:{server.server_port}/synthetic.bin",str(part),str(pid),str(rc),"15",str(stop)]
        proc=subprocess.Popen(cmd,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        try:
            limit=time.monotonic()+10
            while time.monotonic()<limit and not (pid.exists() and part.exists() and part.stat().st_size>=32768):
                time.sleep(0.005)
            assert pid.exists() and part.exists()
            stop.write_text("1")
            try: os.kill(int(pid.read_text()),signal.SIGTERM)
            except ProcessLookupError: pass
            proc.wait(timeout=10)
            n=part.stat().st_size
            assert 0<n<len(DATA),(n,len(DATA))
            assert rc.read_text().strip()=="143"
        finally:
            if proc.poll() is None: proc.terminate();proc.wait(timeout=5)
        stop.unlink()
        subprocess.run(cmd,check=True,timeout=20,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        assert RANGES and RANGES[-1]==n,RANGES
        assert part.read_bytes()==DATA
        print("FETCH PAUSE RANGE: OK - arquivo parcial real e retomada byte a byte")
finally:
    server.shutdown()
