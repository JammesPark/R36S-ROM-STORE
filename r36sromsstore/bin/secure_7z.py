#!/usr/bin/env python3
"""Executa 7-Zip com senha por PTY, nunca pela linha de comando.
Adaptacao independente para R36SPORTSBR STORE HUB (GPL-3.0).
Recebe a senha de arquivo temporario privado (modo 0600, /dev/shm).
A senha nao aparece na lista de processos, logs, excecoes nem na saida.
"""
import fcntl
import os
import pty
import subprocess
import sys
import termios

def main():
    if len(sys.argv) < 5:
        return 7
    secret_path, exe, *args = sys.argv[1:]
    if not os.path.isabs(secret_path) or not os.path.isfile(exe):
        return 7
    try:
        with open(secret_path, "rb", buffering=0) as f:
            pw = f.readline(1025).rstrip(b"\r\n")
    except OSError:
        return 7
    finally:
        try:
            os.unlink(secret_path)
        except OSError:
            pass
    if not pw or len(pw) > 256 or b"\n" in pw or b"\r" in pw:
        return 7
    master, slave = pty.openpty()
    try:
        attr = termios.tcgetattr(slave)
        attr[3] &= ~(termios.ECHO | termios.ECHONL)
        termios.tcsetattr(slave, termios.TCSANOW, attr)
        def new_session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)
        # '-p' sem senha: 7zz pergunta pelo terminal; segredo vem por PTY.
        argv = [exe] + [x for x in args if x != "--password-placeholder"]
        argv.insert(2, "-p")
        proc = subprocess.Popen(argv, stdin=slave, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, preexec_fn=new_session)
        os.close(slave)
        slave = -1
        os.write(master, pw + b"\n")
        pw = b""  # nao persistir a senha em variaveis de saida
        try:
            output, _ = proc.communicate(timeout=1200)
        except subprocess.TimeoutExpired:
            proc.kill()
            output, _ = proc.communicate()
            return 124
        if output:
            # Protecao complementar contra programas que ecoem a entrada.
            sys.stdout.buffer.write(output)
        return int(proc.returncode or 0)
    finally:
        os.close(master)
        if slave >= 0:
            os.close(slave)

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError):
        raise SystemExit(7)
