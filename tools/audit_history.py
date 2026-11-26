#!/usr/bin/env python3
"""Check reachable Git objects and packed content. Reports object IDs, never values."""
import argparse
import collections
import hashlib
import io
import re
import subprocess
import sys
import zipfile
import zlib

MIB = 1024 * 1024
MAX_OBJECT = 128 * MIB
MAX_EXPANDED = 384 * MIB
URL = re.compile(rb'https?://[^/\s:@]{1,128}:[^/\s@]{1,256}@', re.I)
TEMPLATE = b'https://' + b'x-access-token:' + b'$TOKEN@'
# An earlier scanner stores its allowlist as Python source. Identify only
# its exact source line. Other matches, even on the same blob, get inspected.
OLD_ASSERTION = (b'if match.group()==b"' + TEMPLATE +
                 b'" and data[match.end():].startswith(b"github.com/"):')
RULES = [
    ('github', (b'ghp_', b'gho_', b'ghu_', b'ghs_', b'ghr_', b'github_pat_'),
     rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,255}|github_pat_[A-Za-z0-9_]{50,255})\b'),
    ('aws', (b'AKIA', b'ASIA'), rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    ('private-key', (b'-----BEGIN',), rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----'),
    ('slack', (b'xox',), rb'\bxox[baprs]-[A-Za-z0-9-]{15,}'),
    ('google', (b'AIza',), rb'\bAIza[0-9A-Za-z_-]{35}\b'),
    ('openai', (b'sk-',), rb'\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}'),
    ('cloudflare', (b'v1.0-',), rb'\bv1\.0-[a-zA-Z0-9-]{100,}'),
]
RULES = [(name, prefixes, re.compile(pattern)) for name, prefixes, pattern in RULES]

class Audit:
    def __init__(self):
        self.seen = set()
        self.stats = collections.Counter()
        self.hits = []
        self.gaps = []

    def inspect(self, data, oid, depth=0):
        key = hashlib.sha256(data).digest()
        if key in self.seen:
            return
        self.seen.add(key)
        for name, prefixes, pattern in RULES:
            if any(prefix in data for prefix in prefixes):
                for match in pattern.finditer(data):
                    self.hits.append((name, oid, match.start()))
        if b'@' in data and b'://' in data:
            for match in URL.finditer(data):
                if match.group() == TEMPLATE:
                    if data.startswith(b'github.com/', match.end()):
                        self.stats['shell_templates'] += 1
                        continue
                    start = data.rfind(b'\n', 0, match.start()) + 1
                    end = data.find(b'\n', match.end())
                    if data[start:end if end >= 0 else len(data)].strip() == OLD_ASSERTION:
                        self.stats['historical_scanner_literal'] += 1
                        continue
                self.hits.append(('url-userinfo', oid, match.start()))
        if data.startswith(b'version https://git-lfs.github.com/spec/v1\n'):
            self.gaps.append(('LFS pointer', oid))
            return
        is_zip = data.startswith((b'PK\x03\x04', b'PK\x05\x06'))
        # The project ships DEFLATE catalogs without a ZIP container.
        is_zlib = len(data) >= 2 and data[0] == 0x78 and data[1] in (1, 0x5e, 0x9c, 0xda)
        is_gzip = data.startswith(b'\x1f\x8b')
        if not (is_zip or is_zlib or is_gzip):
            if data.startswith((b"7z\xbc\xaf\x27\x1c", b'Rar!\x1a\x07', b'\xfd7zXZ\0', b'BZh')):
                self.gaps.append(('unsupported archive', oid))
            return
        if depth >= 6:
            self.gaps.append(('archive depth', oid))
            return
        if is_zip:
            self.stats['zip'] += 1
            try:
                with zipfile.ZipFile(io.BytesIO(data)) as archive:
                    used = 0
                    for member in archive.infolist():
                        if member.is_dir():
                            continue
                        used += member.file_size
                        if member.flag_bits & 1 or member.file_size > MAX_OBJECT or used > MAX_EXPANDED:
                            self.gaps.append(('archive budget/encryption', oid))
                            continue
                        self.inspect(archive.read(member), oid, depth + 1)
            except (ValueError, OSError, RuntimeError, EOFError, zipfile.BadZipFile, zlib.error):
                self.gaps.append(('unreadable ZIP', oid))
        else:
            try:
                inflater = zlib.decompressobj(31 if is_gzip else 15)
                decoded = inflater.decompress(data, MAX_OBJECT + 1)
                if not inflater.eof or inflater.unused_data or len(decoded) > MAX_OBJECT:
                    self.gaps.append(('compressed stream boundary', oid))
                    return
                self.stats['gzip' if is_gzip else 'zlib'] += 1
                self.inspect(decoded, oid, depth + 1)
            except zlib.error:
                self.gaps.append(('unreadable compressed stream', oid))

    def repository(self, repo):
        git = ['git', '-C', str(repo)]
        args = ['rev-list', '--objects', '--all', '--no-object-names']
        ids = subprocess.check_output(git + args).splitlines()
        info = subprocess.check_output(git + ['cat-file', '--batch-check'], input=b'\n'.join(ids) + b'\n')
        with subprocess.Popen(git + ['cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as proc:
            try:
                for line in info.splitlines():
                    oid, kind, length = line.split()
                    size = int(length)
                    self.stats[kind.decode()] += 1
                    if size > MAX_OBJECT:
                        self.gaps.append(('object size', oid.decode()))
                        continue
                    proc.stdin.write(oid + b'\n')
                    proc.stdin.flush()
                    if proc.stdout.readline().strip() != line:
                        raise ValueError('Git object metadata mismatch')
                    data = proc.stdout.read(size)
                    if len(data) != size or proc.stdout.read(1) != b'\n':
                        raise ValueError('Incomplete Git object')
                    self.inspect(data, oid.decode())
            finally:
                proc.stdin.close()
                if proc.wait() != 0:
                    raise RuntimeError('git cat-file failed')
        print('Objects and formats:', dict(sorted(self.stats.items())))
        print('Distinct payloads:', len(self.seen), 'findings:', len(self.hits), 'coverage gaps:', len(self.gaps))
        for row in self.hits + self.gaps:
            print(*row)
        return 1 if self.hits or self.gaps else 0

def self_test():
    a = Audit()
    a.inspect(TEMPLATE + b'github.com/owner/test', 'shell')
    a.inspect(OLD_ASSERTION, 'history')
    ordinary = b'https://' + b'tester:' + b'dummy-value@example.invalid/'
    joined = io.BytesIO()
    with zipfile.ZipFile(joined, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('fixture', ordinary)
    a.inspect(zlib.compress(joined.getvalue()), 'nested')
    a.inspect(TEMPLATE + b'other.invalid/', 'other')
    assert [(x[0], x[1]) for x in a.hits] == [('url-userinfo','nested'),('url-userinfo','other')]
    assert a.stats['historical_scanner_literal'] == a.stats['shell_templates'] == 1
    assert not a.gaps
    a.inspect(b'PK\x03\x04incomplete', 'invalid')
    assert a.gaps == [('unreadable ZIP','invalid')]
    print('Scanner regression tests passed')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo', nargs='?')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.repo:
        sys.exit(Audit().repository(args.repo))
    if not args.self_test:
        parser.error('specify a repository or --self-test')
